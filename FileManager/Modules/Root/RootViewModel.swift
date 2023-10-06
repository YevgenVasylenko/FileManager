//
//  RootViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 13.09.2023.
//

import SwiftUI

class RootViewModel: ObservableObject {
    struct State {
        let files = [LocalFileManager().rootFolder, DropboxFileManager().rootFolder]
        var selectedFile: File?
        var detailNavigationStack = NavigationPath()
        var isDropboxLogged = false
    }

    @Published
    var state: State
    
    init() {
        self.state = State()
        reloadLoggedState()
//        let selectedFile = state.files[0]
//        state.detailNavigationStack.append(selectedFile)
    }
    
    func loggingToCloud() {
        switch state.selectedFile?.storageType {
        case .dropbox:
            DropboxLoginManager.login()
        case .local, .none:
            break
        }
        reloadLoggedState()
    }
    
    func logoutFromCloud() {
        switch state.selectedFile?.storageType {
        case .dropbox:
            DropboxLoginManager.logout()
        case .local, .none:
            break
        }
        reloadLoggedState()
    }
    
    func isLoggedToCloud() -> Bool {
        switch state.selectedFile?.storageType {
        case .local, .none:
            return false
        case .dropbox:
            return state.isDropboxLogged
        }
    }
    
    private func reloadLoggedState() {
        state.isDropboxLogged = DropboxLoginManager.isLogged
    }
}
