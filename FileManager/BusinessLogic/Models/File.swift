//
//  File.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import Foundation

struct File {

    enum FolderAffiliation {
        case user
        case system
    }
    
    enum ObjectType {
        case folder
        case image
        case text
    }
    
    var folderAffiliation: FolderAffiliation = .user
    var path: URL
    var actions: [FileAction] = []

    init(path: URL) {
        self.path = path
    }
    
    var name: String {
        path.lastPathComponent
    }
    
    var fileType: ObjectType {
        typeDefine()
    }
    
    func makeSubfile(name: String) -> File {
        return File(path: self.path.appendingPathComponent(name, isDirectory: true))
    }
    
    func rename(name: String) -> File {
        return File(path: self.path.deletingLastPathComponent().appendingPathComponent(name))
    }
    
    mutating func addTimeToName() {
        let newName = name + Date.now.formatted(date: .omitted, time: .standard)
        path = self.rename(name: newName).path
    }
    
    func typeDefine() -> ObjectType {
        if self.name.contains(".png") {
            return .image
        }
        return .folder
    }
}

extension File: Hashable {
    
    static func == (lhs: File, rhs: File) -> Bool {
        return lhs.path == rhs.path
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

