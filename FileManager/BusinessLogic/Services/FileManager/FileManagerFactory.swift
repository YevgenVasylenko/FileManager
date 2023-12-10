//
//  FileManagerFactory.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 05.08.2023.
//

import Foundation

class FileManagerFactory {

    static func makeFileManager(storage: File.StorageType) -> FileManager & LocalTemporaryFolderConnector {
        switch storage {
        case .local:
            return LocalFileManager()
        case .dropbox:
            return DropboxFileManager()
        }
    }
}
