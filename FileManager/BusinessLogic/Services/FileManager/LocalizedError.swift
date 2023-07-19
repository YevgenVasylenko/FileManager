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
    
// make Rswift string
        var errorDescription: String? {
            switch self {
            case .nameExist:
                return "Name is exist"
            case .unknown:
                return "Unknown error"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .nameExist:
                return "File with same name is already exist"
            case .unknown:
                return "Try smth else"
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
