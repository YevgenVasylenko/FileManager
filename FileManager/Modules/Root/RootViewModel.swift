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
        var searchingName = ""
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
    
    private func reloadLoggedState() {
        state.isDropboxLogged = DropboxLoginManager.isLogged
    }
}

