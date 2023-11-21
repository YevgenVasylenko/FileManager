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
        Database.Tables.Tags.deleteFromDB(tag: tag)
        updateTagsList()
    }

    func renameTag(tag: Tag, newName: String) {
        Database.Tables.Tags.renameTag(tag: tag, newName: newName) { [weak self] result in
            switch result {
            case .success:
                state.tagForRename = nil
                updateTagsList()
            case .failure(let error):
                state.tagForRename = nil
                self?.state.error = error
            }
        }
    }
}

private extension RootViewModel {

    func reloadLoggedState() {
        state.isDropboxLogged = DropboxLoginManager.isLogged
    }

    func updateTagsList() {
        state.tags = Database.Tables.Tags.getTagsFromDB()
    }
}
