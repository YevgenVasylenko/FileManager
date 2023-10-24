//
//  File+FolderAffiliation.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 24.10.2023.
//

import Foundation

extension File {
    enum FolderAffiliation: Equatable {
        enum SystemFolderName {
            case trash
            case download
        }

        case user
        case system(SystemFolderName)

        static func < (lhs: Self, rhs: Self) -> ComparisonResult {
            switch (lhs, rhs) {
            case (.user, .system):
                return .orderedDescending
            case (.system, .user):
                return .orderedAscending
            case (.system, .system),
                (.user, .user):
                return .orderedSame
            }
        }

        var isSystem: Bool {
            switch self {
            case .system: return true
            default: return false
            }
        }
    }
}
