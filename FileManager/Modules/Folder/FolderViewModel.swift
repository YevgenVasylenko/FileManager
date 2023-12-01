//
//  FolderViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 06.07.2023.
//

import Foundation

final class FolderViewModel: ObservableObject {
    
    struct State {
        var content: Content
        var files: [File] = []
        var isLoading = true
        var error: Error?
        var nameConflict: NameConflict?
        var fileActionType: FileActionType?
        var chosenFiles: Set<File>?
        var folderCreating: String?
        var fileDisplayOptions: FileDisplayOptions
        var deletingFromTrash = false
        var searchingInfo = SearchingInfo()
        var newNameForRename = ""
    }
    
    private var conflictCompletion: ((ConflictNameResult) -> Void)?
    private var fileManagerCommutator = FileManagerCommutator()
    private lazy var folderMonitor = makeFolderMonitor()
    private let debouncer = Debouncer()
    
    @Published
    var state: State

    init(content: Content) {
        self.state = State(content: content, fileDisplayOptions: FileDisplayOptionsManager.options)
        folderMonitor?.folderDidChange = { [weak self] in
            self?.loadContent()
        }
        state.searchingInfo.searchingRequest.placeForSearch = defaultPlaceForSearch()
    }
    
    var filesForAction: [File] {
        if let files = state.chosenFiles {
            return Array(files)
        } else {
            return []
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
    
    func loadContent() {
        switch state.content {
        case .folder(let file):
            loadContentOfFolder(folder: file)
        case .tag(let tag):
            loadTagedFiles(tag: tag)
        }
        makeAtributesForFiles()
    }
    
    func loadContentSearchedByName() {
        state.isLoading = true
        guard let searchingPlace = state.searchingInfo.searchingRequest.placeForSearch else { return }
        debouncer.perform(timeInterval: 1.5) { [weak self] in
            guard let self else { return }
            Database.Tables.SearchHistory.update(newSearchName: self.state.searchingInfo.searchingRequest.searchingName)
            switch self.state.content {
            case .folder(let file):
                self.fileManagerCommutator.contentBySearchingName(
                    searchingPlace: searchingPlace,
                    file: file,
                    name: self.state.searchingInfo.searchingRequest.searchingName
                ) {
                    [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let files):
                        self.state.files = files
                    case .failure(let failure):
                        self.state.error = failure
                    }
                }
            case .tag(let tag):
                LocalFileManager().contentBySearchingNameInTag(
                    tag: tag,
                    name: self.state.searchingInfo.searchingRequest.searchingName) {
                        [weak self] result in
                        guard let self else { return }
                        switch result {
                        case .success(let files):
                            self.state.files = files
                        case .failure(let failure):
                            self.state.error = failure
                        }
                    }
            }
            self.sort()
            self.state.isLoading = false
        }
    }
    
    func startCreatingFolder() {
        switch state.content {
        case .folder(let file):
            fileManagerCommutator.newNameForCreationOfFolder(
                at: file,
                newFolderName: R.string.localizable.newFolder()
            ) {
                [weak self] result in
                switch result {
                case .success(let file):
                    self?.state.folderCreating = file.name
                case .failure:
                    break
                }
            }
        case .tag:
            break
        }
    }
    
    func createFolder(newName: String) {
        switch state.content {
        case .folder(let file):
            state.folderCreating = nil
            let createdFile = file.makeSubfile(name: newName, isDirectory: true)
            state.isLoading = true
            fileManagerCommutator.createFolder(at: createdFile) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    break
                case .failure(let failure):
                    self.state.error = failure
                }
                self.state.isLoading = false
            }
        case .tag:
            break
        }
    }

    func copyChosen() {
        self.state.fileActionType = .copy
    }

    func moveChosen() {
        self.state.fileActionType = .move
    }
    
    func moveToTrash() {
        fileManagerCommutator.moveToTrash(filesToTrash: filesForAction) { [weak self] result in
            switch result {
            case .success:
                self?.state.chosenFiles = nil
            case .failure(let failure):
                self?.state.error = failure
            }
        }
    }

    func restoreFromTrash() {
        fileManagerCommutator.restoreFromTrash(
            filesToRestore: filesForAction,
            conflictResolver: self
        ) { [weak self] result in
            switch result {
            case .success:
                self?.state.chosenFiles = nil
            case .failure(let failure):
                self?.state.error = failure
            }
        }
    }
    
    func startDeleting() {
        state.deletingFromTrash = true
    }
    
    func delete() {
        fileManagerCommutator.deleteFile(files: filesForAction) { [weak self] result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                self?.state.error = failure
            }
        }
    }

    func isFilesInCurrentFolder(files: [File]) -> Bool? {
        if state.isLoading {
            return nil
        } else {
            return state.files.contains(files)
        }
    }
    
    func update(fileDisplayOptions: FileDisplayOptions) {
        FileDisplayOptionsManager.options = fileDisplayOptions
        state.fileDisplayOptions = fileDisplayOptions
        sort()
    }
    
    func sort() {
        let sortOption = state.fileDisplayOptions.sort
        let isAscending = sortOption.direction.isAscending
        switch sortOption.attribute {
        case .name:
            sortForAffiliationOrder(ascending: isAscending) {
                $0.name
            }
        case .type:
            sortForAffiliationOrder(ascending: isAscending) {
                $0.path.pathExtension
            }
        case .date:
            sortForAffiliationOrder(ascending: isAscending) {
                $0.attributes?.createdDate ?? Date()
            }
        case .size:
            sortForAffiliationOrder(ascending: isAscending) {
                $0.attributes?.size ?? 0.0
            }
        }
    }
    
    func isFolderOkForFolderCreationButton() -> Bool {
        switch state.content {
        case .folder(let file):
           return file.hasParent(file: LocalFileManager().trashFolder) == false &&
            file.folderAffiliation != .system(.trash)
        case .tag:
            return false
        }
    }
    
    func suggestedPlacesForSearch() -> [SearchingPlace] {
        switch state.content {
        case .folder(let file):
            switch file.folderAffiliation {
            case .user:
                return SearchingPlace.allCases
            case .system(.root):
                return SearchingPlace.whenInRootOrTrashFolder
            case .system(.trash):
                return SearchingPlace.whenInRootOrTrashFolder
            default:
                return SearchingPlace.allCases
            }
        case .tag:
            return []
        }
    }

    func defaultPlaceForSearch() -> SearchingPlace {
        switch state.content {
        case .folder(let file):
            switch file.folderAffiliation {
            case .user:
                return .currentFolder
            case .system(.root):
                return .currentStorage
            case .system(.trash):
                return .currentTrash
            default:
                return .currentFolder
            }
        case .tag:
            return .currentStorage
        }
    }

    func updateSearchingSuggestingNames() {
        state.searchingInfo.suggestedSearchingNames = Database.Tables.SearchHistory.getSearchNamesFromDB()
    }
}

// MARK: - Private

private extension FolderViewModel {
    
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
                    self?.state.chosenFiles = nil
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
                    self?.state.chosenFiles = nil
                case .failure(let failure):
                    self?.state.error = failure
                }
            }
        }
    }
    
    func makeAtributesForFiles() {
        for i in state.files.indices {
            fileManagerCommutator.getFileAttributes(file: state.files[i]) { [weak self] result in
                switch result {
                case .success(let attributes):
                    self?.state.files[i].attributes = attributes
                case .failure(let failure):
                    self?.state.error = failure
                }
            }
        }
    }

    func sortForAffiliationOrder(
        ascending: Bool,
        field: (File) -> some Comparable
    ) {
        state.files.sort { file1, file2 in
            let affiliationOrder = file1.folderAffiliation < file2.folderAffiliation
            switch affiliationOrder {
            case .orderedAscending:
                return true
            case .orderedDescending:
                return false
            case .orderedSame:
                let result = field(file1) < field(file2)
                return result == ascending
            }
        }
    }

    func makeFolderMonitor() -> FolderMonitor? {
        switch state.content {
        case .folder(let file):
            return fileManagerCommutator.makeFolderMonitor(file: file)
        case .tag:
            return nil
        }
    }

    func loadContentOfFolder(folder: File) {
        folderMonitor?.startMonitoring()
        state.isLoading = true
        fileManagerCommutator.contents(of: folder) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let files):
                self.state.files = files
            case .failure(let failure):
                self.state.error = failure
            }
            self.sort()
            self.state.isLoading = false
        }
    }

    func loadTagedFiles(tag: Tag) {
        state.isLoading = true
        LocalFileManager().filesWithTag(tag: tag) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let files):
                self.state.files = files
            case .failure(let failure):
                self.state.error = failure
            }
            self.sort()
            self.state.isLoading = false
        }
    }
}

extension FolderViewModel: NameConflictResolver {
    func resolve(conflictedFile: File, placeOfConflict: File, completion: @escaping (ConflictNameResult) -> Void) {
        self.state.nameConflict = .resolving(conflictedFile, placeOfConflict)
        self.conflictCompletion = completion
    }
}

enum FileDisplayOptionsManager {

    private static var _options: FileDisplayOptions?

    static var options: FileDisplayOptions {
        get {
            if let options = _options {
                return options
            }
            let options = decodeOptions() ?? .initial
            _options = options
            return options
        }
        set {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "displayOptionData")
            }
            _options = newValue
        }
    }
    
    private static func decodeOptions() -> FileDisplayOptions? {
        var options: FileDisplayOptions?
        if let displayOptionData = UserDefaults.standard.object(forKey: "displayOptionData") as? Data {
            let decoder = JSONDecoder()
            if let displayOptionDecoded = try? decoder.decode(FileDisplayOptions.self, from: displayOptionData) {
                options = displayOptionDecoded
            }
        }
        return options
    }
}
