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
    let type: FileActionType
    let selectedFiles: [File]
    let selected: (File?) -> Void
}

struct SortOption: Hashable {
    enum Attribute: CaseIterable, Hashable {
        case name
        case type
        case date
        case size
    }

    enum Direction: Hashable {
        case ascending
        case descending
        
        func toggled() -> Self {
            switch self {
            case .ascending: return .descending
            case .descending: return .ascending
            }
        }
    }

    let attribute: Attribute
    var direction: Direction?
}

enum FolderShowOption {
    case grid
    case list
}

class FolderViewModel: ObservableObject {

    struct State {
        var folder: File
        var files: [File] = []
        var isLoading = true
        var error: Error?
        var nameConflict: NameConflict?
        var fileActionType: FileActionType?
        var file: File?
        var isFileRenameInProgress = false
        var chosenFiles: Set<File>?
        var folderCreating: String?
        var fileInfoPopover: File?
        var sorted: SortOption?
        var showOption: FolderShowOption = .grid
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
        state.isLoading = true
        fileManagerCommutator.contents(of: file) { result in
            switch result {
            case .success(let files):
                self.state.files = files
            case .failure(let failure):
                self.state.error = failure
            }
            self.state.isLoading = false
        }
        makeAtributesForFiles()
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
        state.isLoading = true
        fileManagerCommutator.createFolder(at: createdFile) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self.state.error = failure
            }
            self.state.isLoading = false
        }
    }
    
    func copyChosen() {
        self.state.fileActionType = .copy
    }

    func moveChosen() {
        self.state.fileActionType = .move
    }
    
    func moveToTrashChosen() {
        moveToTrash()
    }

    func restoreFromTrashChosen() {
        restoreFromTrash()
    }
    
    func deleteChosen() {
        delete()
    }

    func isFilesInCurrentFolder(files: [File]) -> Bool? {
        if state.isLoading {
            return nil
        } else {
            return state.files.contains(files)
        }
    }
    
    func sort(sortOption: SortOption) {
        self.state.sorted = sortOption
        switch sortOption.attribute {
        case .name:
            switch sortOption.direction! {
            case .ascending:
                state.files.sort {
                    $0.name < $1.name
                }
            case .descending:
                state.files.sort {
                    $0.name > $1.name
                }
            }
        case .type:
            switch sortOption.direction! {
            case .ascending:
                state.files.sort {
                    $0.path.pathExtension < $1.path.pathExtension
                }
            case .descending:
                state.files.sort {
                    $0.path.pathExtension > $1.path.pathExtension
                }
            }
        case .date:
            switch sortOption.direction! {
            case .ascending:
                state.files.sort {
                    $0.attributes?.createdDate ?? Date() > $1.attributes?.createdDate ?? Date()
                }
            case .descending:
                state.files.sort {
                    $0.attributes?.createdDate ?? Date() < $1.attributes?.createdDate ?? Date()
                }
            }
        case .size:
            switch sortOption.direction! {
            case .ascending:
                state.files.sort {
                    $0.attributes?.size ?? 0.0 > $1.attributes?.size ?? 0.0
                }
            case .descending:
                state.files.sort {
                    $0.attributes?.size ?? 0.0 < $1.attributes?.size ?? 0.0
                }
            }
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
                conflictResolver: self
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
                conflictResolver: self
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
    
    func makeAtributesForFiles() {
        for i in state.files.indices {
            fileManagerCommutator.getFileAttributes(file: state.files[i]) { result in
                switch result {
                case .success(let attributes):
                    self.state.files[i].attributes = attributes
                case .failure(let failure):
                    self.state.error = failure
                }
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
