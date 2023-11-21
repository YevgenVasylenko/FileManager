//
//  Tag.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 20.11.2023.
//

import Foundation

struct Tag: Hashable {
    let name: String
    let color: TagColor?
}


enum TagColor: Int, CaseIterable, Hashable {
    case red = 0xe81416
    case orange = 0xffa500
    case yellow = 0xfaeb36
    case green = 0x79c314
    case blue = 0x487de7
    case indigo = 0x4b369d
    case violet = 0x70369d
    case grey = 0x808080

    static func allColorsWithNames() -> [Tag] {
        var allColors: [Tag] = []
        for color in Self.allCases {
            allColors.append(Tag(name: localizedColorNamesForDB(tag: color), color: color))
        }
        return allColors
    }

    static func localizedColorNamesForDB(tag: TagColor) -> String {
       switch tag {
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
    }
}

