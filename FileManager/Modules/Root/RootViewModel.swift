//
//  RootViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 13.09.2023.
//

import SwiftUI

final class RootViewModel: ObservableObject {
    struct State {
        var selectedContent: Content?
        var contentStorages: [Content] = [
            .folder(LocalFileManager().rootFolder),
            .folder(DropboxFileManager().rootFolder)
        ]
        var contentTags: [Content] = []
        var detailNavigationStack = NavigationPath()
        var isDropboxLogged = false
        var tagForRename: Tag?
        var newNameForTag: String = ""
        var error: Error?
        var filesWithTag: [File] = []
    }
    
    @Published
    var state = State() {
        didSet {
            if state.selectedContent != oldValue.selectedContent {
                state.detailNavigationStack = .init()
            }
        }
    }
    
    init() {
        reloadLoggedState()
        updateTagsList()
        state.selectedContent = state.contentStorages.first
        NotificationCenter.default.addObserver(self, selector: #selector(updateTagsList), name: TagManager.tagsUpdated, object: nil)
    }
    
    func loggingToCloud() {
        switch state.selectedContent {
        case .folder(let file):
            switch file.storageType {
            case .dropbox:
                DropboxLoginManager.login()
            case .local:
                break
            }
        case .tag, .none:
            break
        }
        reloadLoggedState()
    }
    
    func logoutFromCloud() {
        switch state.selectedContent {
        case .folder(let file):
            switch file.storageType {
            case .dropbox:
                DropboxLoginManager.logout()
            case .local:
                break
            }
        case .tag, .none:
            break
        }
        reloadLoggedState()
    }
    
    func isLoggedToCloud() -> Bool {
        switch state.selectedContent {
        case .folder(let file):
            switch file.storageType {
            case .dropbox:
                return state.isDropboxLogged
            case .local:
                return false
            }
        case .tag, .none:
            return false
        }
    }
    
    func isShouldConnectSelectedStorage() -> Bool {
        isLoggedToCloud() || isSelectedContentIsLocalStorage()
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
        state.contentTags = TagManager.shared.tags.map { Content.tag($0) }
    }

    func deleteTagFromFilesWithSuch(tag: Tag) {
        LocalFileManager().filesWithTag(tag: tag) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let files):
                for file in files {
                    file.path.removeExtendedAttributeFromFile(forName: tag.name)
                }
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }

    func renameTagInFiles(tag: Tag, name: String) {
        LocalFileManager().filesWithTag(tag: tag) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let files):
                for file in files {
                    file.path.removeExtendedAttributeFromFile(forName: tag.name)
                    file.path.setExtendedAttributeToFile(data: Data(), forName: name)
                }
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }

    func isSelectedContentIsLocalStorage() -> Bool {
        switch state.selectedContent {
        case .folder(let file):
            return file.storageType.isLocal
        case .tag:
            return true
        case .none:
            return false
        }
    }
}
