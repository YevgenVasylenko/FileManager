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
    case delete
    case clean
    
    static let trashFolderActions: [Self] = [.clean]
    static let downloadsFolderActions: [Self] = []
    static let regularFolder: [Self] = [.rename, .move, .copy, moveToTrash, .delete, .clean]
}
