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
        TagManager.shared.addNewTag(name: state.newTagName, color: state.selectedColorForNewTag?.color)
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
            name: NotificationNames.tagsUpdated, object: nil
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
        let tagIds = state.selectedTags.map { $0.id }
        fileManagerCommutator.addTagsToFile(
            file: state.file,
            tagIds: tagIds) { result in
                switch result {
                case .success:
                    break
                case .failure:
                    break
                }
            }
    }

    func fillActiveTags() {
        fileManagerCommutator.getActiveTagIdsOnFile(file: state.file) { result in
            switch result {
            case .success(let tagIds):
                for tag in self.state.tags {
                    if tagIds.contains(tag.id) {
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
