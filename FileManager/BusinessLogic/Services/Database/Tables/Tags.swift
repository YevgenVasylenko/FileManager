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

        static func create() {
            do {
                try Database.connection.run(
                    table.create() { t in
                        t.column(id, primaryKey: .autoincrement)
                        t.column(tagName, unique: true)
                        t.column(tagColor, unique: false)
                    }
                )
            } catch {
                print(error)
                return
            }
            writeDefaultTagsInDB()
        }

        static func insertRowToDB(tag: Tag) {
            if tag.name.isEmpty { return }
            do {
                let query = table.insert(
                    tagName <- tag.name,
                    tagColor <- tag.color?.rawValue ?? 0x000000
                )
                try Database.connection.run(query)
            } catch {
                print(error)

            }
        }

        static func renameTag(tag: Tag, newName: String, completion: (Swift.Result<Void, Error>) -> Void) {
            do {
                let renameTagQuery = table.filter(tagName == tag.name)
                try Database.connection.run(renameTagQuery.update(tagName <- newName))
                completion(.success(()))
            } catch {
                completion(.failure(.tagExist))
            }
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
                let tagsFromDB = try Database.connection.prepare(table)
                for tag in tagsFromDB {
                    let name = tag[tagName]
                    let color = tag[tagColor]
                    tags.append(Tag(name: name, color: TagColor(rawValue: color)))
                }
            } catch {
                print(error)
            }
            return tags
        }
    }
}

private extension Database.Tables.Tags {
   static func writeDefaultTagsInDB() {
        for tag in TagColor.allColorsWithNames() {
            Self.insertRowToDB(tag: tag)
        }
    }
}
