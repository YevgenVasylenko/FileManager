//
//  LocalizedError.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 11.07.2023.
//

import Foundation
import SwiftyDropbox

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
  
    init(error: Swift.Error) {
        let error = error as NSError
        switch error.code {
        case NSFileWriteFileExistsError:
            self = .nameExist
        default:
            self = .unknown
        }
    }
    
    init(error: CallError<Files.ListFolderError>) {
        switch error {
            
        default:
            self = .unknown
        }
    }
}
