//
//  Tag.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 20.11.2023.
//

import Foundation

struct Tag: Hashable {
    let name: String
    let color: TagsColors
}


enum TagsColors: String, CaseIterable, Hashable {
    case red = "#e81416"
    case orange = "#ffa500"
    case yellow = "#faeb36"
    case green = "#79c314"
    case blue = "#487de7"
    case indigo = "#4b369d"
    case violet = "#70369d"
    case grey = "#808080"
    case none = ""

    static func allColorsWithNames() -> [Tag] {
        var allColors: [Tag] = []
        for color in Self.allCases {
            allColors.append(Tag(name: localizedColorNamesForDB(tag: color), color: color))
        }
        return allColors
    }

    static func create(rawValue: String) -> TagsColors {
            if let rawValue = TagsColors(rawValue: rawValue) {
                return rawValue
            }
            else{
                return .none
            }
        }

    static func localizedColorNamesForDB(tag: TagsColors) -> String {
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
       case .none:
           return ""
       }
    }
}

