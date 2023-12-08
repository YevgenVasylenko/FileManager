//
//  File+StorageType.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 24.10.2023.
//

import Foundation

extension File {
    enum StorageType: Equatable, CaseIterable {
        case local
        case dropbox

        var isLocal: Bool {
            switch self {
            case .local:
                return true
            case .dropbox:
                return false
            }
        }

        var isDropbox: Bool {
            switch self {
            case .local:
                return false
            case .dropbox:
                return true
            }
        }

        static func activeStorages() -> [FileManager] {
            return File.StorageType.allCases.compactMap {
                let fileManager = FileManagerFactory.makeFileManager(storage: $0)
                if fileManager.isStorageLogged(fileManager: fileManager) {
                    return fileManager
                } else {
                    return nil
                }
            }
        }
    }
}
