//
//  Database.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 10.10.2023.
//

import Foundation
import SQLite

enum Database {
    static let connection = makeConnection()
    
    static func createTables() {
        Tables.FilesInTrash.create()
        Tables.SearchHistory.create()
        Tables.Tags.create()
    }

    static func isTableExists(name: String) -> Bool {
        do {
            let query = "SELECT EXISTS (SELECT * FROM sqlite_master WHERE type = 'table' AND name = ?)"
            return try self.connection.scalar(query, name) as! Int64 != 0
        } catch {
            print(error)
            return true
        }
    }

    private static func makeConnection() -> Connection {
        let pathForConnection = "\(LocalFileMangerRootPath().documentsURL)/db.sqlite3"
        do {
            guard let db = try? Connection(pathForConnection) else { fatalError() }
            return db
        }
    }
}

extension Database {
    enum Tables {}
}
