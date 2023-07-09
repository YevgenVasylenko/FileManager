//
//  PreviewFiles.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 08.07.2023.
//

import Foundation

enum PreviewFiles {
    static let fileManager = LocalFileManager(fileManagerRootPath: TestFileMangerRootPath())
    static let rootFolder = fileManager.rootFolder
    static let trashFolder = fileManager.trashFolder
    static let downloadsFolder = fileManager.downloadsFolder
    
    static let filesInTrash = [trashFolder.makeSubfile(name: "File1"), trashFolder.makeSubfile(name: "File2"), trashFolder.makeSubfile(name: "File3")]
    
    static let filesInRoot = [rootFolder.makeSubfile(name: "File1"), rootFolder.makeSubfile(name: "File2"), rootFolder.makeSubfile(name: "File3")]
    
    static func createFoldersInTrash() -> [File] {
        for file in filesInTrash + filesInRoot {
            fileManager.createFolder(at: file) { result in
                switch result {
                case .success:
                    print("ok")
                case .failure:
                    print("ok")
                }
            }
        }
        return filesInTrash + filesInRoot
    }
}
