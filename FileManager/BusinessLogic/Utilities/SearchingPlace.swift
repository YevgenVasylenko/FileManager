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
}

struct SearchingInfo: Equatable {
    struct SearchingRequest: Equatable {
        var searchingName = ""
        var placeForSearch: SearchingPlace?
    }
    var searchingRequest = SearchingRequest()
    var suggestedSearchingNames: [String] = []
}

