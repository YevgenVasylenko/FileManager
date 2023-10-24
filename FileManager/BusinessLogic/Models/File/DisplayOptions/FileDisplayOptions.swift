//
//  FileDisplayOptions.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 24.10.2023.
//

import Foundation

struct FileDisplayOptions: Codable {
    var layout: LayoutOption
    var sort: SortOption

    static var initial = Self(layout: .grid, sort: SortOption(attribute: .name))
}
