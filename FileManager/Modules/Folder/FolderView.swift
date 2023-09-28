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

    init(
        file: File,
        fileSelectDelegate: FileSelectDelegate?
    ) {
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
                FolderGridListView(
                    files: viewModel.state.files,
                    fileSelectDelegate: fileSelectDelegate,
                    selectedFiles: $viewModel.state.chosenFiles
                )
                if viewModel.state.folder.folderAffiliation != .system(.trash) {
                    createFolderButton()
                }
                actionMenuBarForChosenFiles()
            }
        }
        .onAppear {
            if EnvironmentUtils.isPreview == false {
                viewModel.loadContent()
            }
        }
        .destinationPopover(
            actionType: viewModel.state.fileActionType,
            files: viewModel.filesForAction,
            moveOrCopyToFolder: viewModel.moveOrCopyWithUserChosen
        )
        .conflictPopover(
            conflictName: viewModel.state.nameConflict,
            resolveConflictWithUserChoice: viewModel.userConflictResolveChoice
        )
        .fileCreatingPopover(viewModel: viewModel, newName: $newName)
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
                                viewModel.moveToTrash()
                            }
                            .buttonStyle(.automatic)
                            Spacer()
                        } else if viewModel.state.folder.storageType.isDropbox {
                            Button(R.string.localizable.restore.callAsFunction()) {
                                viewModel.restoreFromTrash()
                            }
                            .buttonStyle(.automatic)
                        } else if viewModel.state.folder.storageType.isLocal {
                            Button(R.string.localizable.delete.callAsFunction()) {
                                viewModel.delete()
                            }
                            .buttonStyle(.automatic)
                        }
                    }
                    .disabled(viewModel.filesForAction.isEmpty)
                }
            }
        }
    }

    func navigationBar(chooseAction: @escaping () -> Void) -> some View {
        HStack {
            FolderShowOptionsView() { options in
                viewModel.update(fileDisplayOptions: options)
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
}

private extension View {
  
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

//struct FolderView_Previews: PreviewProvider {
//    static var previews: some View {
//        FolderView(
//            viewModel: FolderViewModel(
//                file: PreviewFiles.rootFolder,
//                state: .init(folder: PreviewFiles.rootFolder,
//                             files: PreviewFiles.filesInTrash)), fileSelectDelegate: nil)
//    }
//}
