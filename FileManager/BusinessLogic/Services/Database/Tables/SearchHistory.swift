//
//  SearchHistory.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 11.11.2023.
//

import Foundation
import SQLite

extension Database.Tables {
    enum SearchHistory {
        static let table = Table("searchHistory")
        static let id = Expression<Int64>("id")
        static let searchName = Expression<String>("searchName")

        static func create() {
            do {
                try Database.connection.run(
                    table.create(ifNotExists: true) { t in
                        t.column(id, primaryKey: .autoincrement)
                        t.column(searchName, unique: true)
                    }
                )
            } catch {
                print(error)
            }
        }

        static func update(newSearchName: String) {
            if newSearchName.isEmpty { return }
            do {
                try Database.connection.transaction {
                    let query = table.select(searchName).filter(searchName == newSearchName)
                    if try Database.connection.scalar(query.count) > 0 {
                        return
                    }
                    insertRowToDB(newSearchName: newSearchName)
                    deleteOldRows(newSearchName: newSearchName)
                }
            } catch {
                print(error)
            }
        }

        static func getSearchNamesFromDB() -> [String] {
            var searchNames: [String] = []
            let query = table.select(searchName).order(id.desc)
            do {
                let names = try Database.connection.prepare(query)
                for name in names {
                    let name = name[searchName]
                    searchNames.append(name)
                }
            } catch {
                print(error)
            }
            return searchNames
        }
    }
}

// MARK: - Private

private extension Database.Tables.SearchHistory {

    static func insertRowToDB(newSearchName: String) {
        do {
            let query = table.insert(searchName <- newSearchName)
            try Database.connection.run(query)
        } catch {
            print(error)
        }
    }

    static func deleteOldRows(newSearchName: String) {
        if !isShouldDeleteOldRows() { return }
        do {
            let firstRow = table.select(searchName).limit(1)
            try Database.connection.run(firstRow.delete())
        } catch {
            print(error)
        }
    }

    static func isShouldDeleteOldRows() -> Bool {
        do {
            let numberOfNames = try Database.connection.scalar(table.count)
            return numberOfNames > 3
        } catch {
            print(error)
            return false
        }
    }
}
