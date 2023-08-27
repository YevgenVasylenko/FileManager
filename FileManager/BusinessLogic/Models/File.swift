//
//  File.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import Foundation

struct File {

    enum FolderAffiliation: Equatable {
        enum systemFolderName {
            case trash
            case download
        }
        
        case user
        case system(systemFolderName)
    }
    
    enum StorageType: Equatable {
        static func == (lhs: File.StorageType, rhs: File.StorageType) -> Bool {
            switch (lhs, rhs) {
            case (.local, .dropbox):
                return false
            case (.dropbox, .dropbox):
                return true
            case (.local, .local):
                return true
            case (.dropbox, .local):
                return false
            }
        }
        
        case local(LocalStorageData)
        case dropbox(DropboxStorageData)
        
        var local: LocalStorageData {
            switch self {
            case .local(let local):
                return local
            case .dropbox:
                fatalError()
            }
        }
        
        var dropbox: DropboxStorageData {
            switch self {
            case .local:
                fatalError()
            case .dropbox(let dropbox):
                return dropbox
            }
        }
        
        var isLocal: Bool {
            switch self {
            case .local:
                return true
            case .dropbox:
                return false
            }
        }
        
        var isDropbox: Bool {
            switch self {
            case .local:
                return false
            case .dropbox:
                return true
            }
        }
    }
    
    var folderAffiliation: FolderAffiliation = .user
    var actions: [FileAction] = []
    let storageType: StorageType
    var path: URL
    var isDeleted = false

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

    var fileType: ObjectType {
        typeDefine()
    }
    
    func makeSubfile(name: String, isDirectory: Bool = false) -> File {
        return File(
            path: self.path.appendingPathComponent(name, isDirectory: isDirectory),
            storageType: storageType
        )
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
 }

extension File: Hashable {
    
    static func == (lhs: File, rhs: File) -> Bool {
        return lhs.path == rhs.path
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

struct LocalStorageData {
}

struct DropboxStorageData {
}


