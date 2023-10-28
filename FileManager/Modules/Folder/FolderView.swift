//
//  FolderView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FolderView: View {
    
    @StateObject
    private var viewModel: FolderViewModel
    
    @State
    private var newName: String = ""
    
    private let fileSelectDelegate: FileSelectDelegate?

    init(
        file: File,
        fileSelectDelegate: FileSelectDelegate?
    ) {
        self._viewModel = StateObject(wrappedValue: FolderViewModel(file: file))
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    init(viewModel: FolderViewModel, fileSelectDelegate: FileSelectDelegate?) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        suggestedPlaceForSearchMenuBar()
        ZStack {
            if viewModel.state.isLoading {
                ProgressView()
            }
            else {
                folderView()
            }
            if  viewModel.isFolderOkForFolderCreationButton() {
                createFolderButton()
            }
            actionMenuBarForChosenFiles()
        }
        .onChange(of: viewModel.state.searchingName, perform: { newValue in
            if viewModel.state.searchingName.isEmpty {
                viewModel.loadContent()
            } else {
                viewModel.loadContentSearchedByName()
            }
        })
        .onAppear {
            if EnvironmentUtils.isPreview == false {
                viewModel.loadContent()
            }
        }
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
        .fileCreatingPopover(viewModel: viewModel, newName: $newName)
        .errorAlert(error: $viewModel.state.error)
        .navigationViewStyle(.stack)
        .buttonStyle(.plain)
        .padding()
        .navigationTitle(viewModel.state.folder.displayedName())
        .toolbar {
            navigationBar(
                chooseAction: {
                    fileSelectDelegate?.selected(viewModel.state.folder)
                })
        }
    }
}

private extension FolderView {

    func folderView() -> some View {
        let files = viewModel.state.files
        return FolderGridListView(
            files: files,
            fileSelectDelegate: fileSelectDelegate,
            selectedFiles: $viewModel.state.chosenFiles
        )
        .id(files)
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
                        if !viewModel.state.folder.hasParent(file: LocalFileManager().trashFolder) {
                            Spacer()
                            Button(R.string.localizable.copy_to()) {
                                viewModel.copyChosen()
                            }
                            .buttonStyle(.automatic)
                            Spacer()
                            Button(R.string.localizable.move_to()) {
                                viewModel.moveChosen()
                            }
                            .buttonStyle(.automatic)
                            Spacer()
                            Button(R.string.localizable.move_to_trash()) {
                                viewModel.moveToTrash()
                            }
                            .buttonStyle(.automatic)
                            Spacer()
                        } else if viewModel.state.folder.storageType.isLocal {
                            Spacer()
                            Button(R.string.localizable.delete()) {
                                viewModel.startDeleting()
                            }
                            .buttonStyle(.automatic)
                            Spacer()
                            Button(R.string.localizable.restore()) {
                                viewModel.restoreFromTrash()
                            }
                            .buttonStyle(.automatic)
                            Spacer()
                        } else {
                            Button(R.string.localizable.restore()) {
                                viewModel.restoreFromTrash()
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
            Spacer()
                .searchable(text: $viewModel.state.searchingName)
            if let fileSelectDelegate = fileSelectDelegate {
                Button(nameOfActionSelection(fileActionType: fileSelectDelegate.type)) {
                    chooseAction()
                }
                .disabled(viewModel.isFilesInCurrentFolder(files: fileSelectDelegate.selectedFiles) ?? true)
            }
        }
    }
    
    func suggestedPlaceForSearchMenuBar() -> some View {
        Group {
            if !viewModel.state.searchingName.isEmpty {
                HStack {
                    Spacer()
                    ForEach(viewModel.suggestedPlacesForSearch(), id: \.self) { place in
                        Toggle(
                            place.namesForPlaces(file: viewModel.state.folder),
                            isOn: choosePlaceBinding(choicePlace: place)
                        )
                            .toggleStyle(.button)
                            .buttonStyle(.bordered)
                    }
                    Spacer()
                }
            }
        }
    }

    func nameOfActionSelection(fileActionType: FileActionType) -> String {
        switch fileActionType {
        case .copy:
            return R.string.localizable.copy_to()
        case .move:
            return R.string.localizable.move_to()
        }
    }
    
    func nameChangeOfChoose(isChoosing: Bool) -> String {
        if !isChoosing {
            return R.string.localizable.choose()
        } else {
            return R.string.localizable.done()
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
    
    func choosePlaceBinding(choicePlace: SearchingPlace) -> Binding<Bool> {
        Binding(
            get: {
                viewModel.state.placeForSearch == choicePlace
            },
            set: { selected in
                if selected {
                    viewModel.state.placeForSearch = choicePlace
                } else {
                    viewModel.state.placeForSearch = nil
                }
            })
    }
}

private extension View {
  
    func fileCreatingPopover(viewModel: FolderViewModel, newName: Binding<String>) -> some View {
        alert(R.string.localizable.folderCreating(),
              isPresented: .constant((viewModel.state.folderCreating != nil)),
              actions: {
            TextField(viewModel.state.folderCreating ?? "", text: newName)
                .padding()
                .interactiveDismissDisabled()
                .autocorrectionDisabled()
            HStack {
                Button(R.string.localizable.createFolder()) {
                    if newName.wrappedValue.isEmpty {
                        viewModel.createFolder(newName: viewModel.state.folderCreating ?? "")
                    } else {
                        viewModel.createFolder(newName: newName.wrappedValue)
                    }
                    newName.wrappedValue = ""
                }
                Spacer()
                Button(R.string.localizable.cancel()) {
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
