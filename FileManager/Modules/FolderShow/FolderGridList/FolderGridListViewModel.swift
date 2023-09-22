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
        var showOption: FolderShowOption = .grid
    }
    
    private var fileManagerCommutator = FileManagerCommutator()
    private var conflictCompletion: ((ConflictNameResult) -> Void)?

    @Published
    var state: State
    
    init(files: [File]) {
        self.state = State(files: files)
    }
    
    func startRename(file: File) {
        state.file = file
        self.state.isFileRenameInProgress = true
    }
    
    func moveOne(file: File) {
        state.file = file
        self.state.fileActionType = .move
    }
    
    func copyOne(file: File) {
        state.file = file
        self.state.fileActionType = .copy
    }
    
    func moveToTrashOne(file: File) {
        state.file = file
        moveToTrash()
    }
    
    func restoreFromTrashOne(file: File) {
        state.file = file
        restoreFromTrash()
    }
    
    func moveToTrash() {
        fileManagerCommutator.moveToTrash(filesToTrash: [state.file!]) { result in
            switch result {
            case .success:
                self.state.file = nil
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func restoreFromTrash() {
        fileManagerCommutator.restoreFromTrash(filesToRestore: [state.file!]) { result in
            switch result {
            case .success:
                self.state.file = nil
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func deleteOne(file: File) {
        state.file = file
        delete()
    }
    
    func delete() {
        fileManagerCommutator.deleteFile(files: [state.file!]) { result in
            switch result {
            case .success:
                self.state.file = nil
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func clear() {
        fileManagerCommutator.cleanTrashFolder(fileForFileManager: state.file!) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
    
    func rename(newName: String) {
        state.isFileRenameInProgress = false
        fileManagerCommutator.rename(file: state.file!, newName: newName) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
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
    
    func moveFilesToChosen(folder: File) {
        self.state.fileActionType = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)  {
            self.fileManagerCommutator.move(
                files: [self.state.file!],
                destination: folder,
                conflictResolver: self
            ) { result in
                switch result {
                case .success:
                    self.state.file = nil
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
                files: [self.state.file!],
                destination: folder,
                conflictResolver: self
            ) { result in
                switch result {
                case .success:
                    self.state.file = nil
                    break
                case .failure(let failure):
                    self.state.error = failure
                }
            }
        }
    }
    
    func userConflictResolveChoice(nameResult: ConflictNameResult) {
        self.state.nameConflict = nil
        conflictCompletion?(nameResult)
    }
}

extension FolderGridListViewModel: NameConflictResolver {
    func resolve(conflictedFile: File, placeOfConflict: File, completion: @escaping (ConflictNameResult) -> Void) {
        self.state.nameConflict = .resolving(conflictedFile, placeOfConflict)
        self.conflictCompletion = completion
    }
}
