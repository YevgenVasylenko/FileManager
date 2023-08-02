//
//  FileManagerApp.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI
import SwiftyDropbox

@main
struct FileManagerApp: App {
    
    init() {
        DropboxClientsManager.setupWithAppKey("jnv9ukpc8e9kvr7")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

