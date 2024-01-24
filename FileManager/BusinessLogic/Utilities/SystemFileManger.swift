//
//  SystemFileManger.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 23.01.2024.
//

import Foundation

extension SystemFileManger {
    static func createFolder(at file: File) -> Result<Void, Error> {
        do {
            try SystemFileManger.default.createDirectory(at: file.path, withIntermediateDirectories: false)
            return .success(())
        } catch {
            return .failure(Error(error: error))
        }
    }

    static func enumeratorFor(file: File) -> DirectoryEnumerator? {
        return SystemFileManger.default.enumerator(at: file.path, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])
    }

    static func allFilesIn(enumerator: SystemFileManger.DirectoryEnumerator?) -> [File] {
        guard let enumerator
        else {
            return []
        }
        return enumerator.compactMap { element in
            guard let fileURL = element as? URL else {
                return nil
            }
            let newFile = File(path: fileURL, storageType: .local)
            return newFile
        }
    }
}
