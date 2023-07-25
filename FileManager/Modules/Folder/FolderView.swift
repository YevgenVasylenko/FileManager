//
//  FolderView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FolderView: View {
    @ObservedObject var viewModel: FolderViewModel
    @State var newName: String = ""

    let fileSelectDelegate: FileSelectDelegate?
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
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
                if viewModel.state.loading == true {
                    ProgressView()
                }
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach($viewModel.state.files, id: \.self) { $file in
                            VStack {
                                NavigationLink {
                                    viewToShow(file: file)
                                } label: {
                                    FileView(file: file)
                                }
                                if fileSelectDelegate == nil {
                                    fileActionsMenuView(file: file)
                                }
                            }
                            .disabled(viewModel.isFilesDisabledInFolder(isFolderDestinationChose: fileSelectDelegate, file: file))
                            .overlay(alignment: .center) {
                                filesChooseToggle(file: $file)
                            }
                        }
                    }
                }
                createFolderButton()
                actionMenuBarForChosenFiles()
            }
        }
        
        .onAppear {
            if EnvironmentUtils.isPreview == false {
                viewModel.load()
            }
        }
        .renamePopover(viewModel: viewModel, newName: $newName)
        .destinationPopoverFileFolder(viewModule: viewModel)
        .conflictAlertFolder(viewModule: viewModel)
        .errorAlert(error: $viewModel.state.error)
        .navigationViewStyle(.stack)
        .buttonStyle(.plain)
        .padding()
        .navigationTitle(viewModel.state.folder.name)
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
            FolderView(file: file, fileSelectDelegate: fileSelectDelegate)
        }
    }
    
    func createFolderButton() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    viewModel.createFolder()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 70))
                }
                .padding()
            }
        }
    }
    
    func actionMenuBarForChosenFiles() -> some View {
        Group {
            if viewModel.state.filesChooseInProgress {
                VStack {
                    Spacer()
                    HStack {
                        Button(R.string.localizable.copy_to.callAsFunction()) {
                            viewModel.copy()
                        }
                        .buttonStyle(.automatic)
                        Button(R.string.localizable.move_to.callAsFunction()) {
                            viewModel.move()
                        }
                        .buttonStyle(.automatic)
                    }
                    .disabled(viewModel.filesForAction.isEmpty)
                }
            }
        }
    }
    
    func filesChooseToggle(file: Binding<File>) -> some View {
            Group {
                if viewModel.state.filesChooseInProgress && !viewModel.isFileDefault(file: file.wrappedValue) {
                    Toggle(isOn: file.fileChosen) {
                        Image(systemName: file.fileChosen.wrappedValue ? "checkmark.square.fill" : "square")
                            .foregroundColor(file.fileChosen.wrappedValue ? .blue : .gray)
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
            Button {
            } label: {
                Image(systemName: "square.grid.3x3.square")
            }
            if fileSelectDelegate?.type == nil {
                let isChoosing = $viewModel.state.filesChooseInProgress
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
                .disabled(viewModel.isChosenFilesInCurrentView(files: fileSelectDelegate.selectedFiles))
            }
        }
    }
    
    func fileActionsMenuView(file: File) -> some View {
        FileOptionsButtonView(file: file) { action in
            // make file in funcs
            viewModel.state.file = file
            switch action {
            case .rename:
                viewModel.startRename(file: file)
            case .move:
                viewModel.move()
            case .copy:
                viewModel.copy()
            case .moveToTrash:
                viewModel.moveToTrash()
            case .delete:
                viewModel.delete()
            case .clean:
                viewModel.clear()
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
}

extension View {

    func conflictAlertFolder(viewModule: FolderViewModel) -> some View {
        let nameConflict = viewModule.state.nameConflict
        return alert("File with name \(viewModule.state.nameConflict?.file?.name ?? "") is exist", isPresented: .constant(nameConflict != nil)) {
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
        return alert("Enter new name for \(viewModel.state.file?.name ?? "")",
                     isPresented: .constant(viewModel.state.fileRenameInProgress),
                     actions: {
            TextField(R.string.localizable.new_name.callAsFunction(), text: newName)
                .padding()
                .interactiveDismissDisabled()
            HStack {
                Button(R.string.localizable.cancel.callAsFunction()) {
                    viewModel.state.fileRenameInProgress = false
                }
                Spacer()
                Button(R.string.localizable.rename.callAsFunction()) {
                    viewModel.rename(newName: newName.wrappedValue)
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
