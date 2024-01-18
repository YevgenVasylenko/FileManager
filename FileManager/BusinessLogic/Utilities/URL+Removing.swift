//
//  URL+Removing.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 17.01.2024.
//

import Foundation

extension URL {
    func removeTemp() -> URL {
        return URL(string: self.path.deletePrefix(SystemFileManger.default.temporaryDirectory.path)) ?? self
    }

    func removeFirst() -> URL {
        return URL(string: self.pathComponents.dropFirst(2).joined(separator: "/")) ?? self
    }
}
