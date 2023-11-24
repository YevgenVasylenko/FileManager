//
//  FolderGridListView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 18.09.2023.
//

import SwiftUI

struct FolderGridListView: View {

    private let fileSelectDelegate: FileSelectDelegate?
    private let selectedFiles: Binding<Set<File>?>

    @StateObject
    private var viewModel: FolderGridListViewModel

    @State
    private var redraw = Date.now

    init(
        files: [File],
        fileSelectDelegate: FileSelectDelegate?,
        selectedFiles: Binding<Set<File>?>
    ) {
        self._viewModel = StateObject(wrappedValue: FolderGridListViewModel(files: files))
        self.fileSelectDelegate = fileSelectDelegate
        self.selectedFiles = selectedFiles
    }

    var body: some View {
        Group {
            switch FileDisplayOptionsManager.options.layout {
            case .grid: folderGridView()
            case .list: folderListView()
            }
        }
        .renamePopover(viewModel: viewModel, newName: $viewModel.state.newNameForRename)
        .destinationPopover(
            actionType: $viewModel.state.fileActionType,
            files: viewModel.filesForAction,
            moveOrCopyToFolder: viewModel.moveOrCopyWithUserChosen
        )
        .conflictPopover(
            conflictName: viewModel.state.nameConflict,
            resolveConflictWithUserChoice: viewModel.userConflictResolveChoice
        )
        .deleteConfirmationPopover(
            isShowing: $viewModel.state.deletingFromTrash,
            deletingConfirmed: viewModel.delete
        )
        .errorAlert(error: $viewModel.state.error)
    }
}

// MARK: - Private

private extension FolderGridListView {
    
    func columnsForView() -> [GridItem] {
        .init(
            repeating: GridItem(.flexible()),
            count: fileSelectDelegate == nil ? 5 : 4
        )
    }
    
    func fileInfoPopoverBinding(for file: File) -> Binding<Bool> {
        .init(
            get: {
                viewModel.state.fileInfoPopover == file
            },
            set: { isPresented in
                viewModel.state.fileInfoPopover = isPresented ? file : nil
            }
        )
    }

    func tagsPopoverBinding(for file: File) -> Binding<Bool> {
        .init(
            get: {
                viewModel.state.tagsPopover == file
            },
            set: { isPresented in
                viewModel.state.tagsPopover = isPresented ? file : nil
            }
        )
    }
    
    func fileActionsMenuView(file: File) -> some View {
        FileOptionsButtonView(file: file) { action in
            switch action {
            case .rename:
                viewModel.startRename(file: file)
            case .move:
                viewModel.moveOne(file: file)
            case .copy:
                viewModel.copyOne(file: file)
            case .moveToTrash:
                viewModel.moveToTrashOne(file: file)
            case .restoreFromTrash:
                viewModel.restoreFromTrashOne(file: file)
            case .delete:
                viewModel.deleteOne(file: file)
            case .clean:
                viewModel.clear(file: file)
            case .tags:
                viewModel.state.tagsPopover = file
            case .info:
                viewModel.state.fileInfoPopover = file
            }
        }
    }

    @ViewBuilder
    func filesChooseToggle(file: File) -> some View {
        if selectedFiles.wrappedValue != nil && file.folderAffiliation.isSystem == false {
            Toggle(isOn: selectedFileBinding(for: file)) {
                Image(systemName: selectedFileBinding(for: file).wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundColor(selectedFileBinding(for: file).wrappedValue ? .blue : .gray)
                    .font(.system(size: 30))
            }
            .toggleStyle(.button)
        }
    }

    func selectedFileBinding(for file: File) -> Binding<Bool> {
        Binding(
            get: {
                selectedFiles.wrappedValue?.contains(file) ?? false
            },
            set: { selected in
                if selected {
                    selectedFiles.wrappedValue?.insert(file)
                } else {
                    selectedFiles.wrappedValue?.remove(file)
                }
                redraw = .now
            })
    }
    
    func folderListView() -> some View {
        List(viewModel.state.files) { file in
            HStack {
                filesChooseToggle(file: file)
                fileView(file: file, style: .list)
                Spacer()
                showFileActionMenu(file: file)
            }
            .disabled(isFileViewDisabled(file: file))
            .listRowBackground(Color.clear)
        }
        .background(.clear)
        .scrollContentBackground(.hidden)
    }
    
    func folderGridView() -> some View {
        ScrollView {
            LazyVGrid(columns: columnsForView(), spacing: 20) {
                ForEach(viewModel.state.files, id: \.self) { file in
                    ZStack {
                        VStack {
                            fileView(file: file, style: .grid)
                            showFileActionMenu(file: file)
                            Spacer()
                        }
                        .disabled(isFileViewDisabled(file: file))
                        .overlay(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                            filesChooseToggle(file: file)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func fileView(file: File, style: FileView.Style) -> some View {
        switch style {
        case .grid:
            NavigationLink(value: file) {
                FileView(
                    file: file,
                    style: style,
                    infoPresented: fileInfoPopoverBinding(for: file),
                    tagsPresented: tagsPopoverBinding(for: file)
                )
            }
        case .list:
            ListViewItemWithoutDisclosureIndicator(value: file) {
                FileView(
                    file: file,
                    style: style,
                    infoPresented: fileInfoPopoverBinding(for: file),
                    tagsPresented: tagsPopoverBinding(for: file)
                )
            }
        case .info:
            EmptyView()
        }
    }
    
    func isFileViewDisabled(file: File) -> Bool {
        viewModel.isFilesDisabledInFolder(fileSelectDelegate: fileSelectDelegate, file: file) || viewModel.state.fileInfoPopover != nil
    }
    
    @ViewBuilder
    func showFileActionMenu(file: File) -> some View {
        if fileSelectDelegate == nil {
            fileActionsMenuView(file: file)
        }
    }
}

private extension View {
    func renamePopover(viewModel: FolderGridListViewModel, newName: Binding<String>) -> some View {
        alert(
            R.string.localizable.renamePopupTitle()
            + (viewModel.state.file?.name ?? ""),
                     isPresented: .constant(viewModel.state.isFileRenameInProgress),
                     actions: {
            TextField(R.string.localizable.new_name(),
                      text: newName)
                .padding()
                .interactiveDismissDisabled()
                .autocorrectionDisabled()
            HStack {
                Button(R.string.localizable.rename()) {
                    viewModel.rename(newName: newName.wrappedValue)
                    newName.wrappedValue = ""
                }
                Spacer()
                Button(R.string.localizable.cancel()) {
                    viewModel.state.isFileRenameInProgress = false
                    newName.wrappedValue = ""
                }
            }
            .padding()
        })
    }
}
