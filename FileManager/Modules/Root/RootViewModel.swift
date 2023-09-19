//
//  RootViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 13.09.2023.
//

import Foundation

class RootViewModel: ObservableObject {
    struct State {
        var selectedFile: File? = LocalFileManager().rootFolder
        var isDropboxLogged: Bool = false
    }
    
    let files: [File] = [LocalFileManager().rootFolder, DropboxFileManager().rootFolder]

    @Published
    var state: State
    
    init() {
        self.state = State()
    }
    
    func reloadLoggedState() {
        switch state.selectedFile?.storageType {
        case .dropbox:
            state.isDropboxLogged = DropboxLoginManager.isLogged
        case .local, .none:
            break
        }
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
}
