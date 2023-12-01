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

    func namesForPlaces(content: Content) -> String {
        switch content {
        case .folder(let file):
            switch self {
            case .currentStorage:
                switch file.storageType {
                case .local:
                    return R.string.localizable.localStorage()
                case .dropbox:
                    return R.string.localizable.dropboxStorage()
                }
            case .currentFolder:
                return "\(file.displayedName())"
            case .currentTrash:
                return R.string.localizable.currentTrash()
            case .allStorages:
                return R.string.localizable.allStorages()
            }
        case .tag:
            return ""
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

