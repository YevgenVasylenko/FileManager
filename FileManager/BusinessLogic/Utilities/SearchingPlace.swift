//
//  SearchingPlace.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 28.10.2023.
//

import Foundation

enum SearchingPlace: CaseIterable, Equatable {
    case currentStorage
    case currentFolder
    case currentTrash
    case allStorages

    static let whenInRootOrTrashFolder: [Self] = [.currentStorage, .currentTrash, .allStorages]

    static func dependsOnStorageAndAffiliation(file: File) -> [Self] {
        switch file.storageType {

        case .dropbox:
            switch file.folderAffiliation {
            case .user:
                return [.currentStorage, .currentFolder, .allStorages]
            case .system:
                return [.currentStorage, .allStorages]
            }

        case .local:
            switch file.folderAffiliation {
            case .user:
                return Self.allCases
            case .system(.root):
                return Self.whenInRootOrTrashFolder
            case .system(.trash):
                return Self.whenInRootOrTrashFolder
            default:
                return Self.allCases
            }
        }
    }
}

struct SearchingInfo: Equatable {
    struct SearchingRequest: Equatable {
        var searchingName = ""
        var placeForSearch: SearchingPlace?
    }
    var searchingRequest = SearchingRequest()
    var suggestedSearchingNames: [String] = []
}

