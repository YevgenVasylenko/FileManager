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
                        t.column(searchName, unique: false)
                    }
                )
            } catch {
                print(error)
            }
        }

        static func insertOrUpdate(newSearchName: String) {
            if isTableHaveToBeUpdated() {
                updateRowsInTable(newSearchName: newSearchName)
            } else {
                insertRowToDB(newSearchName: newSearchName)
            }
        }

        static func getSearchNamesFromDB() -> [String] {
            var searchNames: [String] = []
            let query = table
                .select(searchName)
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

private extension Database.Tables.SearchHistory {

    static func insertRowToDB(newSearchName: String) {
        do {
            let query = table.insert(searchName <- newSearchName)
            try Database.connection.run(query)
        } catch {
            print(error)
        }
    }

    static func updateRowsInTable(newSearchName: String) {
        do {
            let firstRow = table.select(searchName).filter(id == 1)
            let secondRow = table.select(searchName).filter(id == 2)
            let thirdRow = table.select(searchName).filter(id == 3)

            for name in try Database.connection.prepare(secondRow) {
                try Database.connection.run(firstRow.update(searchName <- name[searchName]))
            }

            for name in try Database.connection.prepare(thirdRow) {
                try Database.connection.run(secondRow.update(searchName <- name[searchName]))
            }

            try Database.connection.run(thirdRow.update(searchName <- newSearchName))
        } catch {
            print(error)
        }
    }

    static func isTableHaveToBeUpdated() -> Bool {
        do {
            let numberOfNames = try Database.connection.scalar(table.count)
            return numberOfNames == 3
        } catch {
            print(error)
            return false
        }
    }
}
