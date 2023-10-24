//
//  SortOption.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 24.10.2023.
//

import Foundation

struct SortOption: Hashable, Codable {
    enum Attribute: CaseIterable, Hashable, Codable {
        case name
        case type
        case date
        case size
    }

    enum Direction: Hashable, Codable {
        case ascending
        case descending

        var isAscending: Bool {
            switch self {
            case .ascending: return true
            case .descending: return false
            }
        }

        func toggled() -> Self {
            switch self {
            case .ascending: return .descending
            case .descending: return .ascending
            }
        }
    }

    let attribute: Attribute
    var direction: Direction = .ascending
}
