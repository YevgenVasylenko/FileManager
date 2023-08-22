//
//  FolderViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 06.07.2023.
//

import Foundation

enum NameConflict {
    case resolving(File, File)
    case resolved(ConflictNameResult)
    
    var conflictedFile: File? {
        switch self {
        case .resolving(let file, _):
            return file
        case .resolved:
            return nil
        }
    }
    
    var placeOfConflict: File? {
        switch self {
        case .resolving(_, let file):
            return file
        case .resolved:
            return nil
        }
    }
}

struct FileSelectDelegate {
    var type: FileActionType
    let selectedFiles: [File]
    let selected: (File?) -> Void
}

class FolderViewModel: ObservableObject {
    
    struct State {
        var folder: File
        var files: [File] = []
        var loading = true
        var error: Error?
        var nameConflict: NameConflict?
        var fileActionType: FileActionType?
        var file: File?
        var fileRenameInProgress = false
        var chosenFiles: Set<File>?
        var folderCreating: String?
        var linkForFilePreview: URL?
    }
    
    private let file: File
    private var conflictCompletion: ((ConflictNameResult) -> Void)?
    private var fileManagerCommutator = FileManagerCommutator()
    private lazy var folderMonitor = fileManagerCommutator.makeFolderMonitor(file: file)
    
    @Published
    var state: State
    
    init(file: File, state: State) {
        self.file = file
        self.state = state
        folderMonitor?.folderDidChange = { [weak self] in
            self?.load()
        }
    }
    
    convenience init(file: File) {
        self.init(file: file, state: State(folder: file))
    }
    
    var filesForAction: [File] {
        if let files = state.chosenFiles {
            return Array(files)
        } else {
            guard let file = state.file else { return [] }
            return [file]
        }
    }
    
    func userConflictResolveChoice(nameResult: ConflictNameResult) {
        self.state.nameConflict = nil
        conflictCompletion?(nameResult)
    }
    
    func moveOrCopyWithUserChosen(folder: File?) {
        if let folder = folder {
            switch self.state.fileActionType {
            case .copy:
                copyFilesToChosen(folder: folder)
            case .move:
                moveFilesToChosen(folder: folder)
            case .none:
                break
            }
        } else {
            state.fileActionType = nil
        }
    }
    
    func load() {
        folderMonitor?.startMonitoring()
        state.loading = true
        fileManagerCommutator.contents(of: file) { result in
            switch result {
            case .success(let files):
                self.state.files = files
            case .failure(let failure):
                self.state.error = failure
            }
            self.state.loading = false
        }
    }
    
    func startCreatingFolder() {
        fileManagerCommutator.newNameForCreationOfFolder(
            at: file,
            newFolderName: R.string.localizable.newFolder.callAsFunction()
        ) { result in
            switch result {
            case .success(let file):
                self.state.folderCreating = file.name
            case .failure:
                return
            }
        }
    }
    
    func createFolder(newName: String) {
        state.folderCreating = nil
        let createdFile = file.makeSubfile(name: newName, isDirectory: true)
        state.loading = true
        fileManagerCommutator.createFolder(at: createdFile) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
            self.state.loading = false
        }
    }
    
    func copyChosen() {
        self.state.fileActionType = .copy
    }
    
    func copyOne(file: File) {
        state.file = file
        self.state.fileActionType = .copy
    }
    
    func moveChosen() {
        self.state.fileActionType = .move
    }
    
    func moveOne(file: File) {
        state.file = file
        self.state.fileActionType = .move
    }
    
    func startRename(file: File) {
        state.file = file
        self.state.fileRenameInProgress = true
    }
    
    func rename(newName: String) {
        state.fileRenameInProgress = false
        fileManagerCommutator.rename(file: state.file!, newName: newName) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func clear() {
        fileManagerCommutator.cleanTrashFolder(fileForFileManager: file) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func moveToTrashChosen() {
        moveToTrash()
    }
    
    func moveToTrashOne(file: File) {
        state.file = file
        moveToTrash()
    }
    
    func restoreFromTrashChosen() {
        restoreFromTrash()
    }
    
    func restoreFromTrashOne(file: File) {
        state.file = file
        restoreFromTrash()
    }
    
    func deleteChosen() {
        delete()
    }
    
    func deleteOne(file: File) {
        state.file = file
        delete()
    }
    
    func getLinkForPreview(file: File) {
        let fileManager = FileManagerFactory.makeFileManager(file: file)
        fileManager.copyToLocalTemporary(files: [file], conflictResolver: self) { result in
            switch result {
            case .success(let urls):
                if let tempURL = urls.first {
                    self.state.linkForFilePreview = tempURL
                }
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func isFilesDisabledInFolder(isFolderDestinationChose: FileSelectDelegate?, file: File) -> Bool {
        guard let isFolderDestinationChose = isFolderDestinationChose else {
            return state.chosenFiles != nil
        }
        return file.folderAffiliation == .system(.trash) || isFolderDestinationChose.selectedFiles.contains(file)
    }
    
    func isFileDefault(file: File) -> Bool {
        return file.folderAffiliation == .system(.download) || file.folderAffiliation == .system(.trash)
    }
    
    func isFilesInCurrentFolder(files: [File]) -> Bool? {
        if state.loading {
            return nil
        } else {
            return state.files.contains(files)
        }
    }
}

private extension FolderViewModel {
    
    func moveFilesToChosen(folder: File) {
        self.state.fileActionType = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)  {
            self.fileManagerCommutator.move(
                files: self.filesForAction,
                destination: folder,
                conflictResolver: self,
                isForOneFile: self.state.chosenFiles == nil
            ) { result in
                switch result {
                case .success:
                    self.state.chosenFiles = nil
                    break
                case .failure(let failure):
                    self.state.error = failure
                }
            }
        }
    }
    
    func copyFilesToChosen(folder: File) {
        self.state.fileActionType = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)  {
            self.fileManagerCommutator.copy(
                files: self.filesForAction,
                destination: folder,
                conflictResolver: self,
                isForOneFile: self.state.file != nil
            ) { result in
                switch result {
                case .success:
                    self.state.chosenFiles = nil
                    break
                case .failure(let failure):
                    self.state.error = failure
                }
            }
        }
    }
    
    func moveToTrash() {
        fileManagerCommutator.moveToTrash(filesToTrash: filesForAction) { result in
            switch result {
            case .success:
                self.state.chosenFiles = nil
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func restoreFromTrash() {
        fileManagerCommutator.restoreFromTrash(filesToRestore: filesForAction) { result in
            switch result {
            case .success:
                self.state.chosenFiles = nil
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func delete() {
        fileManagerCommutator.deleteFile(files: filesForAction) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
}

extension FolderViewModel: NameConflictResolver {
    func resolve(conflictedFile: File, placeOfConflict: File, completion: @escaping (ConflictNameResult) -> Void) {
        self.state.nameConflict = .resolving(conflictedFile, placeOfConflict)
        self.conflictCompletion = completion
    }
}
