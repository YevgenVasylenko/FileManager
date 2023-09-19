//
//  FolderView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FolderView: View {
    
    @ObservedObject
    private var viewModel: FolderViewModel
    
    @State
    private var newName: String = ""
    
    private let fileSelectDelegate: FileSelectDelegate?
    private var columns: [GridItem] {
        columnsForView()
    }
    
    init(file: File, fileSelectDelegate: FileSelectDelegate?) {
        viewModel = FolderViewModel(file: file)
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    init(viewModel: FolderViewModel, fileSelectDelegate: FileSelectDelegate?) {
        self.viewModel = viewModel
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.state.isLoading == true {
                    ProgressView()
                }
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach($viewModel.state.files, id: \.self) { $file in
                            
                            VStack {
                                NavigationLink {
                                    viewToShow(file: file)
                                } label: {
                                    FileView(file: file, infoPresented: fileInfoPopoverBinding(for: file))
                                }
                                if fileSelectDelegate == nil {
                                    fileActionsMenuView(file: file)
                                } else {
                                    Spacer()
                                }
                            }
                            .disabled(viewModel.isFilesDisabledInFolder(
                                isFolderDestinationChose: fileSelectDelegate, file: file) ||
                                      viewModel.state.fileInfoPopover != nil
                            )
                            .overlay(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                                filesChooseToggle(file: file)
                            }
                        }
                    }
                }
                if !(viewModel.state.folder.folderAffiliation == .system(.trash)) {
                    createFolderButton()
                }
                actionMenuBarForChosenFiles()
            }
        }
        .onAppear {
            if EnvironmentUtils.isPreview == false {
                viewModel.load()
            }
        }
        .renamePopover(viewModel: viewModel, newName: $newName)
        .fileCreatingPopover(viewModel: viewModel, newName: $newName)
        .destinationPopoverFileFolder(viewModule: viewModel)
        .conflictAlertFolder(viewModule: viewModel)
        .errorAlert(error: $viewModel.state.error)
        .navigationViewStyle(.stack)
        .buttonStyle(.plain)
        .padding()
        .navigationTitle(viewModel.state.folder.displayedName())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            navigationBar(
                chooseAction: {
                    fileSelectDelegate?.selected(viewModel.state.folder)
                })
        }
    }
}

private extension FolderView {

    func viewToShow(file: File) -> some View {
        Group {
            if file.isFolder() {
                FolderView(file: file, fileSelectDelegate: fileSelectDelegate)
            } else {
                FileContentView(file: file)                    
            }
        }
    }
    
    func createFolderButton() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    viewModel.startCreatingFolder()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                }
                .padding()
            }
        }
    }
    
    func actionMenuBarForChosenFiles() -> some View {
        Group {
            if chooseInProgressBinding().wrappedValue {
                VStack {
                    Spacer()
                    HStack {
                        if viewModel.state.folder.folderAffiliation != .system(.trash) {
                            Spacer()
                            Button(R.string.localizable.copy_to.callAsFunction()) {
                                viewModel.copyChosen()
                            }
                            .buttonStyle(.automatic)
                            Spacer()
                            Button(R.string.localizable.move_to.callAsFunction()) {
                                viewModel.moveChosen()
                            }
                            .buttonStyle(.automatic)
                            Spacer()
                            Button(R.string.localizable.move_to_trash.callAsFunction()) {
                                viewModel.moveToTrashChosen()
                            }
                            .buttonStyle(.automatic)
                            Spacer()
                        } else if viewModel.state.folder.storageType.isDropbox {
                            Button(R.string.localizable.restore.callAsFunction()) {
                                viewModel.restoreFromTrashChosen()
                            }
                            .buttonStyle(.automatic)
                        } else if viewModel.state.folder.storageType.isLocal {
                            Button(R.string.localizable.delete.callAsFunction()) {
                                viewModel.deleteChosen()
                            }
                            .buttonStyle(.automatic)
                        }
                    }
                    .disabled(viewModel.filesForAction.isEmpty)
                }
            }
        }
    }
    
    func filesChooseToggle(file: File) -> some View {
        Group {
            if chooseInProgressBinding().wrappedValue && !viewModel.isFileDefault(file: file) {
                Toggle(isOn: selectedFileBinding(for: file)) {
                    Image(systemName: selectedFileBinding(for: file).wrappedValue ? "checkmark.square.fill" : "square")
                        .foregroundColor(selectedFileBinding(for: file).wrappedValue ? .blue : .gray)
                        .font(.system(size: 30))
                }
                .toggleStyle(.button)
            }
        }
    }
    
    func navigationBar(
        chooseAction: @escaping () -> Void
    ) -> some View {
        HStack {
            FolderShowOptionsView(sortedOption: viewModel.state.sorted) { sortOption in
                viewModel.sort(sortOption: sortOption)
            }
            
            if fileSelectDelegate?.type == nil {
                let isChoosing = chooseInProgressBinding()
                Toggle(nameChangeOfChoose(isChoosing: isChoosing.wrappedValue), isOn: isChoosing)
            }
            
            Button {
            } label: {
                Image(systemName: "magnifyingglass")
            }
            
            if let fileSelectDelegate = fileSelectDelegate {
                Button(nameOfActionSelection(fileActionType: fileSelectDelegate.type)) {
                    chooseAction()
                }
                .disabled(viewModel.isFilesInCurrentFolder(files: fileSelectDelegate.selectedFiles) ?? true)
            }
        }
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
                viewModel.clear()
            case .info:
                viewModel.state.fileInfoPopover = file
            }
        }
    }
    
    func nameOfActionSelection(fileActionType: FileActionType) -> String {
        switch fileActionType {
        case .copy:
            return R.string.localizable.copy_to.callAsFunction()
        case .move:
            return R.string.localizable.move_to.callAsFunction()
        }
    }
    
    func nameChangeOfChoose(isChoosing: Bool) -> String {
        if !isChoosing {
            return R.string.localizable.choose.callAsFunction()
        } else {
            return R.string.localizable.done.callAsFunction()
        }
    }
    
    func selectedFileBinding(for file: File) -> Binding<Bool> {
        return Binding(
            get: {
                viewModel.state.chosenFiles?.contains(file) ?? false
            },
            set: { selected in
                if selected {
                    viewModel.state.chosenFiles?.insert(file)
                } else {
                    viewModel.state.chosenFiles?.remove(file)
                }
            })
    }
    
    func chooseInProgressBinding() -> Binding<Bool> {
        Binding(
            get: {
                viewModel.state.chosenFiles != nil
            },
            set: { selected in
                if selected {
                    viewModel.state.chosenFiles = Set<File>()
                } else {
                    viewModel.state.chosenFiles = nil
                }
            })
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
    
    func columnsForView() -> [GridItem] {
        .init(
            repeating: GridItem(.flexible()),
            count: fileSelectDelegate == nil ? 5 : 4
        )
    }
}

private extension View {

    func conflictAlertFolder(viewModule: FolderViewModel) -> some View {
        let nameConflict = viewModule.state.nameConflict
        return alert(
            R.string.localizable.conflictAlertTitlePart1.callAsFunction() +
            (nameConflict?.placeOfConflict?.displayedName() ?? "") +
            R.string.localizable.conflictAlertTitlePart2.callAsFunction() +
            (nameConflict?.conflictedFile?.name ?? ""),
            isPresented: .constant(nameConflict != nil)
        ) {
            HStack {
                Button(R.string.localizable.cancel.callAsFunction()) {
                    viewModule.userConflictResolveChoice(nameResult: .cancel)
                }
                Button(R.string.localizable.replace.callAsFunction()) {
                    viewModule.userConflictResolveChoice(nameResult: .replace)
                }
                Button(R.string.localizable.new_name.callAsFunction()) {
                    viewModule.userConflictResolveChoice(nameResult: .newName)
                }
            }
        }
    }
    
    func destinationPopoverFileFolder(viewModule: FolderViewModel) -> some View {
        let fileActionType = viewModule.state.fileActionType
        return sheet(isPresented: .constant(fileActionType != nil)) {
            RootView(
                fileSelectDelegate: FileSelectDelegate(type: fileActionType ?? .move,
                selectedFiles: viewModule.filesForAction,
                selected: { file in
                viewModule.moveOrCopyWithUserChosen(folder: file)
            }))
            .interactiveDismissDisabled()
        }
    }
    
    func renamePopover(viewModel: FolderViewModel, newName: Binding<String>) -> some View {
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
    
    func fileCreatingPopover(viewModel: FolderViewModel, newName: Binding<String>) -> some View {
        return alert(R.string.localizable.folderCreating.callAsFunction(),
                     isPresented: .constant((viewModel.state.folderCreating != nil)),
                     actions: {
            TextField(viewModel.state.folderCreating ?? "", text: newName)
                .padding()
                .interactiveDismissDisabled()
                .autocorrectionDisabled()
            HStack {
                Button(R.string.localizable.createFolder.callAsFunction()) {
                    if newName.wrappedValue.isEmpty {
                        viewModel.createFolder(newName: viewModel.state.folderCreating ?? "")
                    } else {
                        viewModel.createFolder(newName: newName.wrappedValue)
                    }
                    newName.wrappedValue = ""
                }
                Spacer()
                Button(R.string.localizable.cancel.callAsFunction()) {
                    viewModel.state.folderCreating = nil
                    newName.wrappedValue = ""
                }
            }
            .padding()
        })
    }
    
    
}

struct FolderView_Previews: PreviewProvider {
    static var previews: some View {
        FolderView(
            viewModel: FolderViewModel(
                file: PreviewFiles.rootFolder,
                state: .init(folder: PreviewFiles.rootFolder,
                             files: PreviewFiles.filesInTrash)), fileSelectDelegate: nil)
    }
}
