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
    private let fileManager = LocalFileManager(fileManagerRootPath: LocalFileMangerRootPath())
    private var conflictCompletion: ((ConflictNameResult) -> Void)?
    private lazy var folderMonitor = FolderMonitor(url: self.file.path)
    
    @Published
    var state: State
    
    init(file: File, state: State) {
        self.file = file
        self.state = state
        folderMonitor.folderDidChange = { [weak self] in
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
        folderMonitor.startMonitoring()
        state.loading = true
        fileManager.contents(of: file) { result in
            switch result {
            case .success(let files):
                //                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [self] in
                self.state.files = files
                //                }
            case .failure(let failure):
                state.error = failure
            }
            state.loading = false
//            folderMonitor.stopMonitoring()
        }
    }
    
    func createFolder() {
        let createdFile = file.makeSubfile(name: "NewFolder")
        state.loading = true
        fileManager.createFolder(at: createdFile) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                state.error = failure
            }
            state.loading = false
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
        fileManager.rename(file: state.file!, newName: newName) { result in
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
        fileManager.deleteFile(files: filesForAction) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func clear() {
        fileManager.cleanTrashFolder { result in
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
    
    func isFilesDisabledInFolder(isFolderDestinationChose: FileSelectDelegate?, file: File) -> Bool {
        guard let isFolderDestinationChose = isFolderDestinationChose else {
            return state.chosenFiles != nil
        }
        return file == fileManager.trashFolder || isFolderDestinationChose.selectedFiles.contains(file)
    }
    
    func isFileDefault(file: File) -> Bool {
        return file.folderAffiliation == .system
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
            self.fileManager.move(files: self.filesForAction, destination: folder, conflictResolver: self) { result in
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
            self.fileManager.copy(files: self.filesForAction, destination: folder, conflictResolver: self) { result in
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
        fileManager.moveToTrash(filesToTrash: filesForAction) { result in
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

extension FolderViewModel: NameConflictResolver {
    func resolve(completion: @escaping (ConflictNameResult) -> Void) {
        self.state.nameConflict = .resolving(file)
        self.conflictCompletion = completion
    }
}
