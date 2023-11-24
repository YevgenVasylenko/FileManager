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

    private var fileManagerCommutator = FileManagerCommutator()

    @Published
    var state: State

    init(file: File) {
        self.state = State(file: file)
        getTagsList()
        NotificationCenter.default.addObserver(self, selector: #selector(getTagsList), name: DatabaseManager.tagsUpdated, object: nil)
    }

    func addNewTag() {
        TagManager.shared.addNewTag(name: state.newTagName, color: state.selectedColorForNewTag?.color)
    }

    func isCreationNewTagButtonDisabled() -> Bool {
        return state.newTagName.isEmpty ||
        state.selectedColorForNewTag == nil ||
        isNameOfNewTagAlreadyExist()
    }
}

// MARK: - Private

private extension TagsMenuViewModel {

    func isNameOfNewTagAlreadyExist() -> Bool {
        return state.tags.contains { tag in
           tag.name == state.newTagName
        }
    }

    @objc
    func getTagsList() {
        state.tags = TagManager.shared.tags
    }
}
