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
                return R.string.localizable.name_is_exist.callAsFunction()
            case .unknown:
                return R.string.localizable.unknown_error.callAsFunction()
            case .dropbox(let description):
                return description
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .nameExist:
                return R.string.localizable.file_with_same_name_is_already_exist.callAsFunction()
            case .unknown:
                return R.string.localizable.try_smth_else.callAsFunction()
            case .dropbox:
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
    
    init<T>(dropboxError: CallError<T>) {
        switch dropboxError {
        case .internalServerError(let int, let string, let string2):
            self = .unknown
        case .badInputError(let string, let string2):
            self = .unknown
        case .rateLimitError(let rateLimitError, let string, let string2, let string3):
            self = .unknown
        case .httpError(let int, let string, let string2):
            self = .unknown
        case .authError(let authError, let string, let string2, let string3):
            self = .unknown
        case .accessError(let accessError, let string, let string2, let string3):
            self = .unknown
        case .routeError(let box, let string, let string2, let string3):
            switch box.unboxed as? Files.RelocationError {
            case .fromLookup(_):
                self = .unknown
            case .fromWrite(let writeError):
                switch writeError {
                case .malformedPath(_):
                    self = .unknown
                case .conflict(let conflict):
                    switch conflict {
                    case .file:
                        self = .nameExist
                    case .folder:
                        self = .nameExist
                    case .fileAncestor:
                        self = .unknown
                    case .other:
                        self = .unknown
                    }
                case .noWritePermission:
                    self = .unknown
                case .insufficientSpace:
                    self = .unknown
                case .disallowedName:
                    self = .unknown
                case .teamFolder:
                    self = .unknown
                case .operationSuppressed:
                    self = .unknown
                case .tooManyWriteOperations:
                    self = .unknown
                case .other:
                    self = .unknown
                }
            case .to(let toError):
                switch toError {
                case .malformedPath(_):
                    self = .unknown
                case .conflict(let conflictError):
                    switch conflictError {
                    case .file:
                        self = .nameExist
                    case .folder:
                        self = .nameExist
                    case .fileAncestor:
                        self = .unknown
                    case .other:
                        self = .unknown
                    }
                case .noWritePermission:
                    self = .unknown
                case .insufficientSpace:
                    self = .unknown
                case .disallowedName:
                    self = .unknown
                case .teamFolder:
                    self = .unknown
                case .operationSuppressed:
                    self = .unknown
                case .tooManyWriteOperations:
                    self = .unknown
                case .other:
                    self = .unknown
                }
            case .cantCopySharedFolder:
                self = .unknown
            case .cantNestSharedFolder:
                self = .unknown
            case .cantMoveFolderIntoItself:
                self = .unknown
            case .tooManyFiles:
                self = .unknown
            case .duplicatedOrNestedPaths:
                self = .unknown
            case .cantTransferOwnership:
                self = .unknown
            case .insufficientQuota:
                self = .unknown
            case .internalError:
                self = .unknown
            case .cantMoveSharedFolder:
                self = .unknown
            case .cantMoveIntoVault(_):
                self = .unknown
            case .cantMoveIntoFamily(_):
                self = .unknown
            case .other:
                self = .unknown
            case .none:
                self = .unknown

            }
            switch box.unboxed as? Files.CreateFolderError {
            case .path(let writeError):
                switch writeError {
                case .conflict(let conflictError):
                    switch conflictError {
                    case .folder:
                        self = .nameExist
                    case .file:
                        self = .nameExist
                    case .fileAncestor:
                        self = .unknown
                    case .other:
                        self = .unknown
                    }
                case .malformedPath(_):
                    self = .unknown
                case .noWritePermission:
                    self = .unknown
                case .insufficientSpace:
                    self = .unknown
                case .disallowedName:
                    self = .unknown
                case .teamFolder:
                    self = .unknown
                case .operationSuppressed:
                    self = .unknown
                case .tooManyWriteOperations:
                    self = .unknown
                case .other:
                    self = .unknown
                }
            case .none:
                break
            }
        case .clientError(let error):
            self = .unknown
        }
    }
}
