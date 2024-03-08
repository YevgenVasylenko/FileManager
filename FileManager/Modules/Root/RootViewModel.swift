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
        var isPhotosToPresent = false
        var contentTags: [Content] = []
        var detailNavigationStack = NavigationPath()
        var isDropboxLogged = false
        var tagForRename: Tag?
        var newNameForTag: String = ""
        var error: Error?
    }

    private var fileManagerCommutator = FileManagerCommutator()

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTagsList),
            name: TagManager.tagsUpdated, object: nil
        )
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
                return true
            }
        case .tag, .none:
            return true
        }
    }
    
    func isShouldConnectSelectedStorage() -> Bool {
        isLoggedToCloud()
//        || isSelectedContentIsLocalStorage()
    }

    func deleteTagFromList(tag: Tag) {
        TagManager.shared.deleteTag(tag: tag)
    }

    func renameTag(tag: Tag, newName: String) {
        self.state.tagForRename = nil
        if let error = TagManager.shared.renameTag(tag: tag, newName: newName) {
            self.state.error = error
        }
    }

    func reloadLoggedState() {
        state.isDropboxLogged = DropboxLoginManager.isLogged
    }
}

// MARK: - Private

private extension RootViewModel {

    @objc
    func updateTagsList() {
        state.contentTags = TagManager.shared.tags.map { Content.tag($0) }
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
