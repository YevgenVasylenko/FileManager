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
    
    func namesForPlaces(file: File) -> String {
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
    }
}

struct SearchingInfo: Equatable {
    var searchingName = ""
    var placeForSearch: SearchingPlace?
    var suggestedSearchingNames: [String] = []
}

