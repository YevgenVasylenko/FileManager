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
        case dropbox(String)
    
        var errorDescription: String? {
            switch self {
            case .nameExist:
                return R.string.localizable.name_is_exist()
            case .unknown:
                return R.string.localizable.unknown_error()
            case .dropbox(let description):
                return description
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
    
    init<T>(dropboxError: CallError<T>) {
        switch dropboxError {
        case .internalServerError(let int, let string, let string2):
            self = .dropbox(string ?? "")
        case .badInputError(let string, let string2):
            self = .dropbox(string ?? "")
        case .rateLimitError(let rateLimitError, let string, let string2, let string3):
            self = .dropbox(string ?? "")
        case .httpError(let int, let string, let string2):
            self = .dropbox(string ?? "")
        case .authError(let authError, let string, let string2, let string3):
            self = .dropbox(string ?? "")
        case .accessError(let accessError, let string, let string2, let string3):
            self = .dropbox(string ?? "")
        case .routeError(let box, let string, let string2, let string3):
            self = .dropbox(string2 ?? "")
        case .clientError(let error):
            self = .unknown
        }
    }
}
