//
//  Tag.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 20.11.2023.
//

import Foundation

struct Tag: Hashable, Identifiable {
    let id: UUID
    let name: String
    let color: TagColor
}

enum TagColor: Int, CaseIterable, Hashable {
    case grey = 0x808080
    case violet = 0x70369d
    case indigo = 0x4b369d
    case blue = 0x487de7
    case green = 0x79c314
    case yellow = 0xfaeb36
    case orange = 0xffa500
    case red = 0xe81416

    static func allTags() -> [Tag] {
        return Self.allCases.map {
            Tag(id: UUID(), name: $0.name(), color: $0)
        }
    }

    private func name() -> String {
#if TESTS
        switch self {
        case .red:
            return "red"
        case .orange:
            return "orange"
        case .yellow:
            return "yellow"
        case .green:
            return "green"
        case .blue:
            return "blue"
        case .indigo:
            return "indigo"
        case .violet:
            return "violet"
        case .grey:
            return "grey"
        }
#else
        switch self {
        case .red:
            return R.string.localizable.red()
        case .orange:
            return R.string.localizable.orange()
        case .yellow:
            return R.string.localizable.yellow()
        case .green:
            return R.string.localizable.green()
        case .blue:
            return R.string.localizable.blue()
        case .indigo:
            return R.string.localizable.indigo()
        case .violet:
            return R.string.localizable.violet()
        case .grey:
            return R.string.localizable.grey()
        }
#endif
    }
}

