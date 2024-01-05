//
//  TagManager.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 24.11.2023.
//

import Foundation

final class TagManager {

    static let shared = TagManager()
    static let tagsUpdated = Notification.Name("TagsUpdated")

    private var _tags: [Tag]?
    var tags: [Tag] {
        get {
            if let tags = _tags {
                return tags
            } else {
                let tags = Database.Tables.Tags.getTagsFromDB()
                _tags = tags
                return tags
            }
        }
    }

    private init() {}

    func addNewTag(name: String, color: TagColor) {
        let newTag = Tag(id: UUID(), name: name, color: color)
        Database.Tables.Tags.insertRowToDB(tag: newTag)
        notifyDbUpdated()
    }

    func deleteTag(tag: Tag) {
        Database.Tables.Tags.deleteFromDB(tag: tag)
        notifyDbUpdated()
    }

    func renameTag(tag: Tag, newName: String) -> Error? {
        let error = Database.Tables.Tags.renameTag(tag: tag, newName: newName)
        notifyDbUpdated()
        return error
    }

    private func notifyDbUpdated() {
        _tags = nil
        NotificationCenter.default.post(name: Self.tagsUpdated, object: nil)
    }
}
