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

enum FileActionType {
    case copy
    case move
}

struct FileSelectDelegate {
    let type: FileActionType
    let selectedFiles: [File]
    let selected: (File) -> Void
}


class FolderViewModel: ObservableObject {
  
    struct State {
        var folder: File
        var files: [File] = []
        var loading: Bool = true
        var error: Error?
        var filesChooseInProgress: Bool = false
        var nameConflict: NameConflict?
        var fileActionType: FileActionType?
        var file: File?
    }
    
    private let file: File
    private let fileManager = LocalFileManager(fileManagerRootPath: LocalFileMangerRootPath())
    private var conflictCompletion: ((ConflictNameResult) -> Void)?
    private lazy var folderMonitor = FolderMonitor(url: self.file.path)
    var filesForAction: [File] {
        if state.filesChooseInProgress {
          return chosenFilesForAction()
        } else {
            guard let file = state.file else { return [] }
           return [file]
        }
    }
    
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
    
    @Published
    var state: State
    
    func userConflictResolveChoice(nameResult: ConflictNameResult) {
        self.state.nameConflict = nil
        conflictCompletion?(nameResult)
    }
    
    func moveOrCopyWithUserChosen(folder: File) {
        switch self.state.fileActionType {
        case .copy:
            copyFilesToChosen(folder: folder)
        case .move:
            moveFilesToChosen(folder: folder)
        case .none:
            break
        }
    }
    
    func load() {
        folderMonitor.startMonitoring()
        state.loading = true
        fileManager.contents(of: file) { result in
            switch result {
            case .success(let files):
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [self] in
                    self.state.files = files
                }
            case .failure(let failure):
                state.error = failure
            }
            state.loading = false
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
    
    func copy() {
        self.state.fileActionType = .copy
    }
    
    func move() {
        self.state.fileActionType = .move
    }
    
    func rename(newName: String = "Hello") {
        fileManager.rename(file: state.file!, newName: newName) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func delete() {
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
    
    func moveToTrash() {
        fileManager.moveToTrash(filesToTrash: [file]) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func isFilesDisabledInFolder(isFolderDestinationChose: FileSelectDelegate?, file: File) -> Bool {
        guard let isFolderDestinationChose = isFolderDestinationChose else {
            return state.filesChooseInProgress
        }
            return isFileDefault(file: file) || isFolderDestinationChose.selectedFiles.contains(file)
    }
    
    func isFileDefault(file: File) -> Bool {
        return file == fileManager.downloadsFolder || file == fileManager.trashFolder
    }
    
    func isChosenFilesInCurrentView(files: [File]) -> Bool {
        return state.files.contains(files)
    }
}

private extension FolderViewModel {
    
    func moveFilesToChosen(folder: File) {
        self.state.fileActionType = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)  {
            self.fileManager.move(files: self.filesForAction, destination: folder, conflictResolver: self) { result in
                switch result {
                case .success:
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
                    break
                case .failure(let failure):
                    self.state.error = failure
                }
            }
        }
    }
    
    func chosenFilesForAction() -> [File] {
        var files: [File] = []
        for file in state.files {
            if file.fileChosen {
                files.append(file)
            }
        }
        return files
    }
}


extension FolderViewModel: NameConflictResolver {
    func resolve(completion: @escaping (ConflictNameResult) -> Void) {
        // make protocol with destination file
        self.state.nameConflict = .resolving(file)
        self.conflictCompletion = completion
    }
}
