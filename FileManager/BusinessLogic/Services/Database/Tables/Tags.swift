//
//  Tags.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 20.11.2023.
//

import Foundation
import SQLite

extension Database.Tables {
    enum Tags {
        static let table = Table("tags")
        static let id = Expression<Int64>("id")
        static let tagName = Expression<String>("tagName")
        static let tagColor = Expression<Int>("tagColor")
        static let tagID = Expression<String>("operationID")

        static func create() {
            do {
                try Database.connection.transaction {
                    if try Database.connection.scalar("SELECT EXISTS (SELECT * FROM sqlite_master WHERE type = 'table' AND name = ?)", "tags") as! Int64 > 0 {
                        return
                    } else {
                        try Database.connection.run(
                            table.create() { t in
                                t.column(id, primaryKey: .autoincrement)
                                t.column(tagName, unique: true)
                                t.column(tagColor, unique: false)
                                t.column(tagID, unique: true)
                            }
                        )
                        writeDefaultTagsInDB()
                    }
                }
            } catch {
                print(error)
            }
        }

        static func insertRowToDB(tag: Tag) {
            if tag.name.isEmpty { return }
            do {
                let query = table.insert(
                    tagName <- tag.name,
                    tagColor <- tag.color.rawValue,
                    tagID <- tag.id.uuidString
                )
                try Database.connection.run(query)
            } catch {
                print(error)
            }
        }

        static func renameTag(tag: Tag, newName: String) -> Error? {
            var _error: Error? = nil
            do {
                try Database.connection.transaction {
                    let query = table.select(tagName).filter(tagName == newName)
                    if try Database.connection.scalar(query.count) > 0 || newName.isEmpty {
                        _error = .tagExist
                    } else {
                        let renameTagQuery = table.filter(tagName == tag.name)
                        try Database.connection.run(renameTagQuery.update(tagName <- newName))
                    }
                }
            } catch {
                _error = Error(error: error)
            }
            return _error
        }

        static func deleteFromDB(tag: Tag) {
            let deleteTagQuery = table.filter(tagName == tag.name)
            do {
                try Database.connection.run(deleteTagQuery.delete())
            } catch {
                print(error)
            }
        }

        static func getTagsFromDB() -> [Tag] {
            var tags: [Tag] = []
            do {
                let tagsFromDB = try Database.connection.prepare(table.order(id.desc))
                for tag in tagsFromDB {
                    let name = tag[tagName]
                    let color = tag[tagColor]
                    let operationID = UUID(uuidString: tag[tagID]) ?? UUID()
                    tags.append(Tag(id: operationID, name: name, color: TagColor(rawValue: color) ?? .grey))
                }
            } catch {
                print(error)
            }
            return tags
        }
    }
}

// MARK: - Private

private extension Database.Tables.Tags {
   static func writeDefaultTagsInDB() {
        for tag in TagColor.allTags() {
            Self.insertRowToDB(tag: tag)
        }
    }
}
