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
