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
//        removeDeselectedTagsFromFile()
    }
}

// MARK: - Private

private extension TagsMenuViewModel {

    func initialSetups() {
        getTagsList()
        NotificationCenter.default.addObserver(self, selector: #selector(getTagsList), name: Notify.tagsUpdated, object: nil)
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
        let tagNames = state.selectedTags.map { $0.name }
        fileManagerCommutator.addTagsToFile(
            file: state.file,
            tagNames: tagNames) { result in
                switch result {
                case .success:
                    break
                case .failure:
                    break
                }
            }
    }

    func fillActiveTags() {
        fileManagerCommutator.getActiveTagNamesOnFile(file: state.file) { result in
            switch result {
            case .success(let tagNames):
                for tag in self.state.tags {
                    if tagNames.contains(tag.name) {
                        self.activeTagsOnFile.insert(tag)
                    }
                }
            case .failure:
                break
            }
        }
    }

    func setSelectedTags() {
        fillActiveTags()
        state.selectedTags = activeTagsOnFile
    }

//    func removeDeselectedTagsFromFile() {
//        let deselectedTags = activeTagsOnFile.subtracting(state.selectedTags)
//        for tag in deselectedTags {
//            state.file.path.removeExtendedAttributeFromFile(forName: tag.name)
//        }
//    }
}
