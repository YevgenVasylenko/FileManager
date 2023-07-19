//
//  FileOptionsButtonViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 09.07.2023.
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
    let selected: (File) -> Void
}

class FileOptionsButtonViewModel: ObservableObject {
    // make state private set, make function to change state
    struct State {
        var file: File
        var error: Error?
        var nameConflict: NameConflict?
        var fileActionType: FileActionType?
    }
    
    let fileManager = LocalFileManager()
    private let file: File
    private var conflictCompletion: ((ConflictNameResult) -> Void)?
    
    @Published
    var state: State
    
    init(file: File) {
        self.file = file
        self.state = State(file: file)
    }
    
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
    
    func rename(newName: String = "Hello") {
        fileManager.rename(file: file, newName: newName) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func delete() {
        fileManager.deleteFile(files: [file]) { result in
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
    
    func copy() {
        self.state.fileActionType = .copy
    }
    
    func move() {
        self.state.fileActionType = .move
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
}

private extension FileOptionsButtonViewModel {
    
    func moveFilesToChosen(folder: File) {
        self.state.fileActionType = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)  {
            self.fileManager.move(files: [self.file], destination: folder, conflictResolver: self) { result in
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
            self.fileManager.copy(files: [self.file], destination: folder, conflictResolver: self) { result in
                switch result {
                case .success:
                    break
                case .failure(let failure):
                    self.state.error = failure
                }
            }
        }
    }
}

extension FileOptionsButtonViewModel: NameConflictResolver {
    func resolve(completion: @escaping (ConflictNameResult) -> Void) {
        // make protocol with destination file
        self.state.nameConflict = .resolving(file)
        self.conflictCompletion = completion
    }
}
