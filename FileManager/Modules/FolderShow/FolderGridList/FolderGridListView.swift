//
//  FolderGridListView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 18.09.2023.
//

import SwiftUI

struct FolderGridListView: View {
    
    @State
    private var newName: String = ""
    
    @ObservedObject
    private var viewModel: FolderGridListViewModel
    private let fileSelectDelegate: FileSelectDelegate?
    private let selectedFiles: Binding<Set<File>?>
    
    @State
    private var redraw = Date.now
    
    private var columns: [GridItem] {
        columnsForView()
    }
    
    init(
        files: [File],
        fileSelectDelegate: FileSelectDelegate?,
        selectedFiles: Binding<Set<File>?>
    ) {
        self.viewModel = FolderGridListViewModel(files: files)
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
        .renamePopover(viewModel: viewModel, newName: $newName)
        .destinationPopover(
            actionType: viewModel.state.fileActionType,
            files: viewModel.filesForAction,
            moveOrCopyToFolder: viewModel.moveOrCopyWithUserChosen
        )
        .conflictPopover(
            conflictName: viewModel.state.nameConflict,
            resolveConflictWithUserChoice: viewModel.userConflictResolveChoice
        )
    }
}

private extension FolderGridListView {
    
    func columnsForView() -> [GridItem] {
        .init(
            repeating: GridItem(.flexible()),
            count: fileSelectDelegate == nil ? 5 : 4
        )
    }
    
    func viewToShow(file: File) -> some View {
        Group {
            if file.isFolder() {
                FolderView(
                    file: file,
                    fileSelectDelegate: fileSelectDelegate
                )
            } else {
                FileContentView(file: file)
            }
        }
    }
    
    func fileInfoPopoverBinding(for file: File) -> Binding<Bool> {
        return Binding(
            get: {
                viewModel.state.fileInfoPopover == file
            },
            set: { isPresented in
                viewModel.state.fileInfoPopover = isPresented ? file : nil
            })
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
            case .info:
                viewModel.state.fileInfoPopover = file
            }
        }
    }
    
    func filesChooseToggle(file: File) -> some View {
        Group {
            if selectedFiles.wrappedValue != nil && file.folderAffiliation.isSystem == false {
                Toggle(isOn: selectedFileBinding(for: file)) {
                    Image(systemName: selectedFileBinding(for: file).wrappedValue ? "checkmark.square.fill" : "square")
                        .foregroundColor(selectedFileBinding(for: file).wrappedValue ? .blue : .gray)
                        .font(.system(size: 30))
                }
                .toggleStyle(.button)
            }
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
                if fileSelectDelegate == nil {
                    fileActionsMenuView(file: file)
                } else {
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .disabled(isFileViewDisabled(file: file))
        }
        .listStyle(.plain)
        .background(.clear)
        .scrollContentBackground(.hidden)
    }
    
    func folderGridView() -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach($viewModel.state.files, id: \.self) { $file in
                    ZStack {
                        VStack {
                            fileView(file: file, style: .grid)
                            if fileSelectDelegate == nil {
                                fileActionsMenuView(file: file)
                            } else {
                                Spacer()
                            }
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
    
    func fileView(file: File, style: FileView.Style) -> some View {
        NavigationLink {
            viewToShow(file: file)
        } label: {
            FileView(file: file, style: style, infoPresented: fileInfoPopoverBinding(for: file))
        }
    }
    
    func isFileViewDisabled(file: File) -> Bool {
        viewModel.isFilesDisabledInFolder(fileSelectDelegate: fileSelectDelegate, file: file) || viewModel.state.fileInfoPopover != nil
    }
}

private extension View {
    func renamePopover(viewModel: FolderGridListViewModel, newName: Binding<String>) -> some View {
        return alert(R.string.localizable.renamePopupTitle.callAsFunction() + (viewModel.state.file?.name ?? ""),
                     isPresented: .constant(viewModel.state.isFileRenameInProgress),
                     actions: {
            TextField(R.string.localizable.new_name.callAsFunction(), text: newName)
                .padding()
                .interactiveDismissDisabled()
                .autocorrectionDisabled()
            HStack {
                Button(R.string.localizable.rename.callAsFunction()) {
                    viewModel.rename(newName: newName.wrappedValue)
                    newName.wrappedValue = ""
                }
                Spacer()
                Button(R.string.localizable.cancel.callAsFunction()) {
                    viewModel.state.isFileRenameInProgress = false
                    newName.wrappedValue = ""
                }
            }
            .padding()
        })
    }
}

//struct SwiftUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
//}
