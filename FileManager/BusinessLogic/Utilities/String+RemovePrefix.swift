//
//  String+RemovePrefix.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 17.01.2024.
//

import Foundation

extension String {
    func deletePrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}
