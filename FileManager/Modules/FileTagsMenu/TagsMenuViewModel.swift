//
//  TagsMenuViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.11.2023.
//

import Foundation

final class TagsMenuViewModel: ObservableObject {

    struct State {
        var file: File
        var tags: [Tag] = []
        var selectedTags: Set<Tag> = []
        var isPresentCreationOfNewTagPopover = false
        var newTagName = ""
        var selectedColorForNewTag: Tag?
    }

    private var activeTagsOnFile: Set<Tag> = []

    @Published
    var state: State

    init(file: File) {
        self.state = State(file: file)
        initialSetups()
    }

    func addNewTag() {
        TagManager.shared.addNewTag(name: state.newTagName, color: state.selectedColorForNewTag?.color)
    }

    func isCreationNewTagButtonDisabled() -> Bool {
        return state.newTagName.isEmpty ||
        state.selectedColorForNewTag == nil ||
        isNameOfNewTagAlreadyExist()
    }

    func updateActiveTagsOnFile() {
        addTagsToFile()
        removeDeselectedTagsFromFile()
    }
}

// MARK: - Private

private extension TagsMenuViewModel {

    func initialSetups() {
        getTagsList()
        NotificationCenter.default.addObserver(self, selector: #selector(getTagsList), name: TagManager.tagsUpdated, object: nil)
        setSelectedTags()
    }

    func isNameOfNewTagAlreadyExist() -> Bool {
        return state.tags.contains { tag in
           tag.name == state.newTagName
        }
    }

    @objc
    func getTagsList() {
        state.tags = TagManager.shared.tags
    }

    func addTagsToFile() {
        for tag in state.selectedTags {
            state.file.path.setExtendedAttributeToFile(data: Data(), forName: tag.name)
        }
    }

    func getActiveTagNamesOnFile() -> [String] {
        return state.file.path.listExtendedAttributesForFile()
    }

    func fillActiveTags() {
       let activeTagNames = getActiveTagNamesOnFile()
        for tag in state.tags {
            if activeTagNames.contains(tag.name) {
                activeTagsOnFile.insert(tag)
            }
        }
    }

    func setSelectedTags() {
        fillActiveTags()
        state.selectedTags = activeTagsOnFile
    }

    func removeDeselectedTagsFromFile() {
        let deselectedTags = activeTagsOnFile.subtracting(state.selectedTags)
        for tag in deselectedTags {
            state.file.path.removeExtendedAttributeFromFile(forName: tag.name)
        }
    }
}
