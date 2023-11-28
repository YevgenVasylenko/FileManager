//
//  RootViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 13.09.2023.
//

import SwiftUI

final class RootViewModel: ObservableObject {
    struct State {
        let storages = [LocalFileManager().rootFolder, DropboxFileManager().rootFolder]
        var selectedStorage: File?
        var detailNavigationStack = NavigationPath()
        var isDropboxLogged = false
        var tags: [Tag] = []
        var selectedTag: Tag?
        var tagForRename: Tag?
        var newNameForTag: String = ""
        var error: Error?
        var filesWithTag: [File] = []
    }
    
    @Published
    var state = State() {
        didSet {
            if state.selectedStorage != oldValue.selectedStorage {
                state.detailNavigationStack = .init()
            }
        }
    }
    
    init() {
        reloadLoggedState()
        updateTagsList()
        state.selectedStorage = state.storages.first
        NotificationCenter.default.addObserver(self, selector: #selector(updateTagsList), name: DatabaseManager.tagsUpdated, object: nil)
    }
    
    func loggingToCloud() {
        switch state.selectedStorage?.storageType {
        case .dropbox:
            DropboxLoginManager.login()
        case .local, .none:
            break
        }
        reloadLoggedState()
    }
    
    func logoutFromCloud() {
        switch state.selectedStorage?.storageType {
        case .dropbox:
            DropboxLoginManager.logout()
        case .local, .none:
            break
        }
        reloadLoggedState()
    }
    
    func isLoggedToCloud() -> Bool {
        switch state.selectedStorage?.storageType {
        case .local, .none:
            return false
        case .dropbox:
            return state.isDropboxLogged
        }
    }
    
    func isShouldConnectSelectedStorage() -> Bool {
        isLoggedToCloud() || state.selectedStorage?.storageType.isLocal ?? true
    }

    func deleteTagFromList(tag: Tag) {
        TagManager.shared.deleteTag(tag: tag)
        deleteTagFromFilesWithSuch(tag: tag)
    }

    func renameTag(tag: Tag, newName: String) {
        TagManager.shared.renameTag(tag: tag, newName: newName) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.state.tagForRename = nil
            case .failure(let error):
                self.state.tagForRename = nil
                self.state.error = error
            }
        }
        renameTagInFiles(tag: tag, name: newName)
    }
}

// MARK: - Private

private extension RootViewModel {

    func reloadLoggedState() {
        state.isDropboxLogged = DropboxLoginManager.isLogged
    }

    @objc
    func updateTagsList() {
        state.tags = TagManager.shared.tags
    }

    func filesWithTag(tag: Tag, completion: @escaping (Result<[File], Error>) -> Void) {
        LocalFileManager().allFilesInLocal {  result in
            switch result {
            case .success(let files):
                let filteredFiles = files.filter { file in
                    do {
                        for tagName in try file.path.listExtendedAttributes() {
                            return tag.name == tagName
                        }
                        return false
                    } catch {
                        return false
                    }
                }
                completion(.success(filteredFiles))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }

    func deleteTagFromFilesWithSuch(tag: Tag) {
        filesWithTag(tag: tag) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let files):
                for file in files {
                    do {
                        try file.path.removeExtendedAttribute(forName: tag.name)
                    } catch {
                        print(error)
                    }
                }
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }

    func renameTagInFiles(tag: Tag, name: String) {
        filesWithTag(tag: tag) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let files):
                for file in files {
                    do {
                        try file.path.removeExtendedAttribute(forName: tag.name)
                        try file.path.setExtendedAttribute(data: Data(), forName: name)
                    } catch {
                        print(error)
                    }
                }
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
}
