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
    private var fileManagerCommutator = FileManagerCommutator()

    @Published
    var state: State

    init(file: File) {
        self.state = State(file: file)
        initialSetups()
    }

    func addNewTag() {
        TagManager.shared.addNewTag(
            name: state.newTagName,
            color: state.selectedColorForNewTag?.color ?? .grey
        )
    }

    func isCreationNewTagButtonDisabled() -> Bool {
        return state.newTagName.isEmpty ||
        state.selectedColorForNewTag == nil ||
        isNameOfNewTagAlreadyExist()
    }

    func updateActiveTagsOnFile() {
        addTagsToFile()
    }
}

// MARK: - Private

private extension TagsMenuViewModel {

    func initialSetups() {
        getTagsList()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(getTagsList),
            name: TagManager.tagsUpdated,
            object: nil
        )
        fillActiveTags()
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
        fileManagerCommutator.addTags(
            to: state.file,
            tags: Array(state.selectedTags)) { result in
                switch result {
                case .success:
                    NotificationCenter.default.post(name: TagManager.tagsUpdated, object: nil)
                case .failure:
                    break
                }
            }
    }

    func fillActiveTags() {
        fileManagerCommutator.getActiveTagIds(on: state.file) { result in
            switch result {
            case .success(let tagIds):
                for tag in self.state.tags {
                    if tagIds.contains(tag.id.uuidString) {
                        self.activeTagsOnFile.insert(tag)
                        self.state.selectedTags = self.activeTagsOnFile
                    }
                }
            case .failure:
                break
            }
        }
    }
}
