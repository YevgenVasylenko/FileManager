//
//  File.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import Foundation

struct File: Hashable {
    
    enum ObjectType {
        case folder
        case image
        case text
    }
    
    var name: String {
        path.lastPathComponent
    }
    
    var path: URL
    
    var fileType: ObjectType {
        typeDefine()
    }

    init(path: URL) {
        self.path = path
    }
    
    func makeSubfile(name: String) -> File {
        return File(path: self.path.appendingPathComponent(name, isDirectory: true))
    }
    
    mutating func rename(name: String) {
        self.path = self.path.deletingLastPathComponent().appendingPathComponent(name)
    }
    
    mutating func addTimeToName() {
        let newName = name + Date.now.formatted(date: .omitted, time: .standard)
        path = path.deletingLastPathComponent().appendingPathComponent(newName)
    }
    
    func typeDefine() -> ObjectType {
        if self.name.contains(".png") {
            return .image
        }
        return .folder
    }
}

extension File: Equatable {
    static func == (lhs: File, rhs: File) -> Bool {
        return lhs.path == rhs.path
    }
}
