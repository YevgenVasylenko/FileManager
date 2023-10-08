//
//  FolderGridListViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 19.09.2023.
//

import Foundation

class FolderGridListViewModel: ObservableObject {
    struct State {
        var file: File?
        var files: [File]
        var fileActionType: FileActionType?
        var fileInfoPopover: File?
        var isFileRenameInProgress = false
        var error: Error?
        var nameConflict: NameConflict?
    }
    
    private var fileManagerCommutator = FileManagerCommutator()
    private var conflictCompletion: ((ConflictNameResult) -> Void)?

    @Published
    var state: State
    
    init(files: [File]) {
        self.state = State(files: files)
    }
    
    var filesForAction: [File] {
        if let file = state.file {
            return [file]
        } else {
            return []
        }
    }
    
    func startRename(file: File) {
        state.file = file
        state.isFileRenameInProgress = true
    }
    
    func moveOne(file: File) {
        state.file = file
        state.fileActionType = .move
    }
    
    func copyOne(file: File) {
        state.file = file
        state.fileActionType = .copy
    }
    
    func moveToTrashOne(file: File) {
        state.file = file
        moveToTrash()
    }
    
    func restoreFromTrashOne(file: File) {
        state.file = file
        restoreFromTrash()
    }
    
   
    func deleteOne(file: File) {
        state.file = file
        delete()
    }
    
    
    func clear(file: File) {
        fileManagerCommutator.cleanTrashFolder(fileForFileManager: file) { [weak self] result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self?.state.error = failure
            }
        }
    }
    
    func rename(newName: String) {
        state.isFileRenameInProgress = false
        guard let file = state.file else { return }
        fileManagerCommutator.rename(file: file, newName: newName) { [weak self] result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self?.state.error = failure
            }
        }
    }
    
    func isFilesDisabledInFolder(fileSelectDelegate: FileSelectDelegate?, file: File) -> Bool {
        guard let fileSelectDelegate = fileSelectDelegate else {
            return false
        }
        return file.folderAffiliation == .system(.trash) || fileSelectDelegate.selectedFiles.contains(file)
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
  
    func userConflictResolveChoice(nameResult: ConflictNameResult) {
        self.state.nameConflict = nil
        conflictCompletion?(nameResult)
    }
}

private extension FolderGridListViewModel {
    
    func delete() {
        fileManagerCommutator.deleteFile(files: filesForAction) { [weak self] result in
            switch result {
            case .success:
                self?.state.file = nil
            case .failure(let failure):
                self?.state.error = failure
            }
        }
    }
    
    func moveToTrash() {
        fileManagerCommutator.moveToTrash(filesToTrash: filesForAction) { [weak self] result in
            switch result {
            case .success:
                self?.state.file = nil
            case .failure(let failure):
                self?.state.error = failure
            }
        }
    }
    
    func restoreFromTrash() {
        fileManagerCommutator.restoreFromTrash(filesToRestore: filesForAction) { [weak self] result in
            switch result {
            case .success:
                self?.state.file = nil
            case .failure(let failure):
                self?.state.error = failure
            }
        }
    }
    
    
    func moveFilesToChosen(folder: File) {
        self.state.fileActionType = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)  {
            self.fileManagerCommutator.move(
                files: self.filesForAction,
                destination: folder,
                conflictResolver: self
            ) { [weak self] result in
                switch result {
                case .success:
                    self?.state.file = nil
                case .failure(let failure):
                    self?.state.error = failure
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
                conflictResolver: self
            ) { [weak self] result in
                switch result {
                case .success:
                    self?.state.file = nil
                case .failure(let failure):
                    self?.state.error = failure
                }
            }
        }
    }
}

extension FolderGridListViewModel: NameConflictResolver {
    func resolve(conflictedFile: File, placeOfConflict: File, completion: @escaping (ConflictNameResult) -> Void) {
        state.nameConflict = .resolving(conflictedFile, placeOfConflict)
        conflictCompletion = completion
    }
}
