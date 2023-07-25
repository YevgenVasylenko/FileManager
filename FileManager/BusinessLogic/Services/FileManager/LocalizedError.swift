//
//  LocalizedError.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 11.07.2023.
//

import Foundation

enum Error: LocalizedError {
        case nameExist
        case unknown
    
        var errorDescription: String? {
            switch self {
            case .nameExist:
                return R.string.localizable.name_is_exist.callAsFunction()
            case .unknown:
                return R.string.localizable.unknown_error.callAsFunction()
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .nameExist:
                return R.string.localizable.file_with_same_name_is_already_exist.callAsFunction()
            case .unknown:
                return R.string.localizable.try_smth_else.callAsFunction()
            }
        }
    // remake on init
    static func errorHandling(error: NSError) -> Self {
        switch error.code {
        case NSFileWriteFileExistsError:
            return .nameExist
        default:
            return .unknown
        }
    }
}
