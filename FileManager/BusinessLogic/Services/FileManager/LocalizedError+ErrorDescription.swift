//
//  LocalizedError+ErrorDescription.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 05.01.2024.
//

import Foundation

extension Error {
    var errorDescription: String? {
        switch self {
        case .nameExist:
            return R.string.localizable.name_is_exist()
        case .tagExist:
            return R.string.localizable.tag_name_is_exist()
        case .fileNotSupported:
            return R.string.localizable.unreadableFile()
        case .dropbox(let description):
            return description
        case .unknown:
            return R.string.localizable.unknown_error()
        }
    }
}
