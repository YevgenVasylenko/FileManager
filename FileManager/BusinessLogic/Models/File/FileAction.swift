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
    
    static let trashFolder: [Self] = [.clean]
    static let downloadsFolder: [Self] = []
    static let regularFile: [Self] = [.rename, .move, .copy, .moveToTrash, .tags, .info]
    static let trashedFiles: [Self] = [.delete, .restoreFromTrash]
}
