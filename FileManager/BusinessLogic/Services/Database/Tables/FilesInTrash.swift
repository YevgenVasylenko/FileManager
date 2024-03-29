//
//  Database+FilesInTrash.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 24.10.2023.
//

import Foundation
import SQLite

extension Database.Tables {
    enum FilesInTrash {
        static let table = Table("filesInTrash")
        static let id = Expression<Int64>("id")
        static let pathInTrash = Expression<String>("pathInTrash")
        static let pathToRestore = Expression<String>("pathToRestore")
        
        static func create() {
            do {
                try Database.connection.run(
                    table.create(ifNotExists: true) { t in
                        t.column(id, primaryKey: .autoincrement)
                        t.column(pathInTrash, unique: true)
                        t.column(pathToRestore, unique: false)
                    }
                )
            } catch {
                print(error)
            }
        }
        
        static func insertRowToFilesInTrashDB(fileToTrash: File, fileInTrashPath: URL) {
            do {
                let query = table.insert(
                    pathToRestore <- pathWithOutHomeDirectory(path: fileToTrash.path),
                    pathInTrash <- pathWithOutHomeDirectory(path: fileInTrashPath)
                )
                try Database.connection.run(query)
            } catch {
                print(error)
            }
        }
        
        static func deleteFromDB(file: File) {
            let deleteFileQuery = table.filter(
                pathInTrash == pathWithOutHomeDirectory(path: file.path)
            )
            do {
                try Database.connection.run(deleteFileQuery.delete())
            } catch {
                print(error)
            }
        }
        
        static func getPathForRestore(file: File) -> URL? {
            let pathInTrashFolder = pathWithOutHomeDirectory(path: file.path)
            if preLastFolder(file: file) == LocalFileManager.Constants.trash {
                let query = table
                    .select(pathToRestore)
                    .where(pathInTrash == pathInTrashFolder)
                do {
                    let files = try Database.connection.prepare(query)
                    for file in files {
                        let pathString = file[pathToRestore]
                        return URL(filePath: NSHomeDirectory().appending(pathString))
                    }
                } catch {
                    print(error)
                }
            } else {
                let query = table
                    .select(pathToRestore)
                    .where(pathInTrash == pathToFolderInTrash(path: file.path.path))
                do {
                    let files = try Database.connection.prepare(query)
                    for fileInDB in files {
                        let pathString = fileInDB[pathToRestore]
                        return URL(filePath: NSHomeDirectory().appending(pathString).appending(pathFromTrashRootToFile(path: file.path.path)))
                    }
                } catch {
                    print(error)
                }
            }
            return nil
        }
    }
}

// MARK: - Private

private extension Database.Tables.FilesInTrash {
    static func pathWithOutHomeDirectory(path: URL) -> String {
        return path.path.replacingOccurrences(of: NSHomeDirectory(), with: "")
    }

    static func preLastFolder(file: File) -> String {
        return file.path.deletingLastPathComponent().lastPathComponent
    }

    static func firstNameInTrash(path: String) -> String {
        return URL(filePath: path.replacingOccurrences(of: LocalFileManager().trashFolder.path.path, with: "")).pathComponents[1]
    }

    static func pathFromTrashRootToFile(path: String) -> String {
        return path.replacingOccurrences(of: LocalFileManager().trashFolder.path.appending(component: firstNameInTrash(path: path)).path, with: "")
    }

    static func pathToFolderInTrash(path: String) -> String {
        let path = LocalFileManager().trashFolder.path.appending(component: firstNameInTrash(path: path))
        return pathWithOutHomeDirectory(path: path)
    }
}
