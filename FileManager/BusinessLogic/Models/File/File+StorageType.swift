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

        var isStorageLogged: Bool {
            switch self {
            case .local:
                return LocalFileManager().isStorageLogged()
            case .dropbox:
                return DropboxFileManager().isStorageLogged()
            }
        }

        static func activeStorages() -> [FileManager] {
            return File.StorageType.allCases.compactMap {
                if $0.isStorageLogged {
                    return FileManagerFactory.makeFileManager(storage: $0)
                } else {
                    return nil
                }
            }
        }
    }
}
