//
//  FolderViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 06.07.2023.
//

import Foundation

enum NameConflict {
    case resolving(File)
    case resolved(ConflictNameResult)
    
    var file: File? {
        switch self {
        case .resolving(let file):
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
    }
    private let file: File
    private let fileManager: FileManager
    private var conflictCompletion: ((ConflictNameResult) -> Void)?
    private lazy var folderMonitor = fileManager.makeFolderMonitor(file: file)
    
    @Published
    var state: State
    
    init(file: File, state: State) {
        self.file = file
        self.state = state
        self.fileManager = FolderViewModel.makeFileManager(file: file)
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
        FileManagerCommutator().contents(of: file) { result in
            switch result {
            case .success(let files):
                self.state.files = files
            case .failure(let failure):
                self.state.error = failure
            }
            self.state.loading = false
        }
    }
    
    func createFolder() {
        let createdFile = file.makeSubfile(name: "NewFolder")
        state.loading = true
        FileManagerCommutator().createFolder(at: createdFile) { result in
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
        FileManagerCommutator().rename(file: state.file!, newName: newName) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func delete(file: File) {
        state.file = file
        FileManagerCommutator().deleteFile(files: filesForAction) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func clear() {
        FileManagerCommutator().cleanTrashFolder(fileForFileManager: file) { result in
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
    
    func isFilesDisabledInFolder(isFolderDestinationChose: FileSelectDelegate?, file: File) -> Bool {
        guard let isFolderDestinationChose = isFolderDestinationChose else {
            return state.chosenFiles != nil
        }
        // not shure
        return file == LocalFileManager().trashFolder || isFolderDestinationChose.selectedFiles.contains(file)
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
            FileManagerCommutator().move(files: self.filesForAction, destination: folder, conflictResolver: self) { result in
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
            FileManagerCommutator().copy(files: self.filesForAction, destination: folder, conflictResolver: self) { result in
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
        FileManagerCommutator().moveToTrash(filesToTrash: filesForAction) { result in
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
        FileManagerCommutator().restoreFromTrash(filesToRestore: filesForAction) { result in
            switch result {
            case .success:
                self.state.chosenFiles = nil
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
   static func makeFileManager(file: File) -> FileManager {
        switch file.storageType {
        case .local:
            return LocalFileManager()
        case .dropbox:
            return DropboxFileManager()
        }
    }
}

extension FolderViewModel: NameConflictResolver {
    func resolve(completion: @escaping (ConflictNameResult) -> Void) {
        self.state.nameConflict = .resolving(file)
        self.conflictCompletion = completion
    }
}
