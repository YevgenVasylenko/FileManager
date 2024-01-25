//
//  URL+Removing.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 17.01.2024.
//

import Foundation

extension URL {
    func removeTemp() -> URL {
        if let url = URL(string: path.deletePrefix(SystemFileManger.default.temporaryDirectory.path)) {
            return url
        } else {
            assertionFailure()
            return self
        }
    }

    func removeFirst() -> URL {
        if let url = URL(string: pathComponents.dropFirst(2).joined(separator: "/")) {
            return url
        } else {
            assertionFailure()
            return self
        }
    }
}
