//
//  Content.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 28.11.2023.
//

import Foundation

enum Content: Hashable {
    case folder(File)
    case tag(Tag)

    func storageTypeOfFolder() -> File.StorageType? {
        switch self {
        case .folder(let file):
            return file.storageType
        case .tag:
            return nil
        }
    }
}
