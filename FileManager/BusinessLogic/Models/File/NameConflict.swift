//
//  NameConflict.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 24.10.2023.
//

import Foundation

enum NameConflict {
    case resolving(File, File)
    case resolved(ConflictNameResult)

    var conflictedFile: File? {
        switch self {
        case .resolving(let file, _):
            return file
        case .resolved:
            return nil
        }
    }

    var placeOfConflict: File? {
        switch self {
        case .resolving(_, let file):
            return file
        case .resolved:
            return nil
        }
    }
}
