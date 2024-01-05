//
//  File.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import Foundation

struct File {    
    var folderAffiliation: FolderAffiliation = .user
    var actions: [FileAction] = []
    let storageType: StorageType
    var path: URL
    var attributes: FileAttributes?
    
    init(path: URL, storageType: StorageType) {
        self.path = path
        self.storageType = storageType
    }
    
    var name: String {
        path.lastPathComponent
    }
    
    var nameWithoutExtension: String {
        path.deletingPathExtension().lastPathComponent
    }
    
    func makeSubfile(name: String, isDirectory: Bool = false) -> File {
        return File(
            path: self.path.appendingPathComponent(name, isDirectory: isDirectory),
            storageType: storageType
        )
    }

    func isFileIsSub(file: File, isDirectory: Bool = false) -> Bool {
        self == file.makeSubfile(name: self.name, isDirectory: isDirectory)
    }
    
    func parentFolder() -> File {
        return File(path: path.deletingLastPathComponent(), storageType: storageType)
    }
    
    func isFolder() -> Bool {
        return path.hasDirectoryPath
    }
    
    func rename(name: String) -> File {
        let fileExtension = self.path.pathExtension
        return File(
            path: self.path
                .deletingLastPathComponent()
                .appendingPathComponent(name)
                .appendingPathExtension(fileExtension),
            storageType: storageType
        )
    }
    
    mutating func addTimeToName() {
        let newName = name + Date.now.formatted(date: .omitted, time: .standard)
        path = self.rename(name: newName).path
    }
    
    func hasParent(file: File) -> Bool {
        path.path.hasPrefix(file.path.path)
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

extension File: Identifiable {
    var id: URL {
        self.path
    }
}

struct FileAttributes {
    let size: Double
    let createdDate: Date?
    let modifiedDate: Date?
}
