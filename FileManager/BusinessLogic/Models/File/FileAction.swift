//
//  FileAction.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 09.07.2023.
//

import Foundation

enum FileAction {
    
    case rename
    case move
    case copy
    case moveToTrash
    case restoreFromTrash
    case delete
    case clean
    case tags
    case info
    
    static let trashFolderActions: [Self] = [.clean]
    static let downloadsFolderActions: [Self] = []
    static let regularFolder: [Self] = [.rename, .move, .copy, .moveToTrash, .tags, .info]
}
