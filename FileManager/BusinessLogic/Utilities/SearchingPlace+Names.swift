//
//  SearchingPlace+Names.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 05.01.2024.
//

import Foundation

extension SearchingPlace {
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
                return "«\(file.displayedName())»"
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
