//
//  Content.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 28.11.2023.
//

import Foundation

enum Content: Hashable {
    case folder(File)
    case tag(Tag)
}
