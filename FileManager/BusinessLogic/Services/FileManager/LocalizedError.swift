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
    case tagExist
    case fileNotSupported
    case dropbox(String)
    case unknown
    
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
        case .internalServerError(_, let string, _):
            self = .dropbox(string ?? "")
        case .badInputError(let string, _):
            self = .dropbox(string ?? "")
        case .rateLimitError(_, let string, _, _):
            self = .dropbox(string ?? "")
        case .httpError(_, let string, _):
            self = .dropbox(string ?? "")
        case .authError(_, let string, _, _):
            self = .dropbox(string ?? "")
        case .accessError(_, let string, _, _):
            self = .dropbox(string ?? "")
        case .routeError(_, _, let string, _):
            self = .dropbox(string ?? "")
        case .clientError:
            self = .unknown
        }
    }
}

