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
            case root
            case trash
            case download
        }
        
        case user
        case system(systemFolderName)
    }
    
    enum ObjectType {
        case folder
        case image
        case text
    }
    
    enum StorageType {
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
    var path: URL
    var actions: [FileAction] = []
    let storageType: StorageType

    init(path: URL, storageType: StorageType) {
        self.path = path
        self.storageType = storageType
    }
    
    var name: String {
        path.lastPathComponent
    }

    var fileType: ObjectType {
        typeDefine()
    }
    
    func makeSubfile(name: String) -> File {
        return File(path: self.path.appendingPathComponent(name, isDirectory: true), storageType: storageType)
    }
    
    func rename(name: String) -> File {
        return File(path: self.path.deletingLastPathComponent().appendingPathComponent(name), storageType: storageType)
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
    
    func displayedName() -> String {
        if self.name == "/" {
            return R.string.localizable.dropbox.callAsFunction()
        }
        switch self.folderAffiliation {
        case .user:
            return self.name
        case .system(.root):
            return R.string.localizable.root.callAsFunction()
        case .system(.trash):
            return R.string.localizable.trash.callAsFunction()
        case .system(.download):
            return R.string.localizable.downloads.callAsFunction()
        }
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
