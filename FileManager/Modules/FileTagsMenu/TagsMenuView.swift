//
//  TagsMenuView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.11.2023.
//
import SwiftUI

struct TagsMenuView: View {

    @Environment(\.dismiss)
    private var dismiss

    @StateObject
    private var viewModel: TagsMenuViewModel

    init(file: File) {
        self._viewModel = StateObject(wrappedValue: TagsMenuViewModel(file: file))
    }

    var body: some View {
        if viewModel.state.isPresentCreationOfNewTagPopover == false {
            tagsList()
        } else {
            creationOfNewTagView()
        }
    }
}

// MARK: - Private

private extension TagsMenuView {

    @ViewBuilder
    func tagsList() -> some View {
        VStack {
            Button(R.string.localizable.add_new_tag()) {
                viewModel.state.isPresentCreationOfNewTagPopover = true
            }
            .buttonStyle(.plain)
            .padding()
            List {
                ForEach(viewModel.state.tags) { tag in
                    Button(action: { toggleSelection(tag: tag) }) {
                        HStack {
                            tagsListItem(tag: tag)
                                .foregroundColor(.black)
                            Spacer()
                            if viewModel.state.selectedTags.contains { $0.id == tag.id } {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .tag(tag.id)
                }
            }
            .listStyle(PlainListStyle())
            Spacer()
        }
        .frame(minWidth: 250, minHeight: 300)
        .onDisappear() {
            viewModel.updateActiveTagsOnFile()
        }
    }

    func toggleSelection(tag: Tag) {
            if let existingIndex = viewModel.state.selectedTags.firstIndex(where: { $0.id == tag.id }) {
                viewModel.state.selectedTags.remove(at: existingIndex)
            } else {
                viewModel.state.selectedTags.insert(tag)
            }
        }

    @ViewBuilder
    func tagsListItem(tag: Tag) -> some View {
        Label {
            Text(tag.name)
        } icon: {
            Image(systemName: "circle.fill")
                .foregroundColor(Color(uiColor: UIColor(rgb: tag.color.rawValue)))
        }
    }

    func creationOfNewTagView() -> some View {
        VStack {
            HStack {
                Button(R.string.localizable.cancel()) {
                    dismiss()
                }
                Spacer()
                Text(R.string.localizable.add_new_tag())
                Spacer()
                Button(R.string.localizable.done()) {
                    viewModel.addNewTag()
                    dismiss()
                }
                .disabled(viewModel.isCreationNewTagButtonDisabled())
            }
            TextField(R.string.localizable.name_of_new_tag(), text: $viewModel.state.newTagName)
                .autocorrectionDisabled(true)
            HStack {
                ForEach(TagColor.allTags()) { tag in
                    Button {
                        viewModel.state.selectedColorForNewTag = tag
                    } label: {
                        ZStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(Color(uiColor: UIColor(rgb: tag.color.rawValue)))
                                .font(.title)
                            if viewModel.state.selectedColorForNewTag?.name == tag.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}
