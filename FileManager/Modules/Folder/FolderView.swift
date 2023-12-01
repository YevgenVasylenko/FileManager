//
//  FolderView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FolderView: View {

    private let fileSelectDelegate: FileSelectDelegate?
    
    @StateObject
    private var viewModel: FolderViewModel

    init(
        content: Content,
        fileSelectDelegate: FileSelectDelegate?
    ) {
        self._viewModel = StateObject(wrappedValue: FolderViewModel(content: content))
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        Searchable(
            searchInfo: $viewModel.state.searchingInfo,
            content: {
                completeFolderView()
            },
            searchableSuggestions: {
                searchSuggestingNames()
            },
            onChanged: { searchInfo in
                viewModel.updateSearchingSuggestingNames()
                if searchInfo.searchingName.isEmpty {
                    viewModel.loadContent()
                }
                else {
                    viewModel.loadContentSearchedByName()
                }
            }
        )
    }
}

// MARK: - Private

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

    @ViewBuilder
    func completeFolderView() -> some View {
        suggestedPlaceForSearchMenuBar()
        ZStack {
            if viewModel.state.isLoading {
                ProgressView()
            }
            else {
                folderView()
            }
            if viewModel.isFolderOkForFolderCreationButton() {
                createFolderButton()
            }
            actionMenuBarForChosenFiles()
        }
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
        .fileCreatingPopover(viewModel: viewModel, newName: $viewModel.state.newNameForRename)
        .errorAlert(error: $viewModel.state.error)
        .navigationViewStyle(.stack)
        .buttonStyle(.plain)
        .padding()
        .navigationTitle(displayedNameForNavigationTitle())
        .toolbar {
            navigationBar(
                chooseAction: {
                    fileSelectDelegate?.selected(fileForFileSelectDelegate())
                })
        }
    }

    @ViewBuilder
    func actionMenuBarForChosenFiles() -> some View {
        if chooseInProgressBinding().wrappedValue {
            VStack {
                Spacer()
                HStack {
                    if isFolderInTrashFolder() {
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
                    } else if isFolderInLocal() {
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

    func navigationBar(chooseAction: @escaping () -> Void) -> some View {
        HStack {
            FolderShowOptionsView() { options in
                viewModel.update(fileDisplayOptions: options)
            }
            if fileSelectDelegate?.type == nil {
                let isChoosing = chooseInProgressBinding()
                Toggle(nameChangeOfChoose(isChoosing: isChoosing.wrappedValue), isOn: isChoosing)
            }
            if let fileSelectDelegate = fileSelectDelegate {
                Button(nameOfActionSelection(fileActionType: fileSelectDelegate.type)) {
                    chooseAction()
                }
                .disabled(viewModel.isFilesInCurrentFolder(files: fileSelectDelegate.selectedFiles) ?? true)
            }
        }
    }

    @ViewBuilder
    func suggestedPlaceForSearchMenuBar() -> some View {
        if viewModel.state.searchingInfo.searchingRequest.searchingName.isEmpty == false {
            HStack(alignment: .top) {
                Spacer()
                ForEach(viewModel.suggestedPlacesForSearch(), id: \.self) { place in
                    Toggle(
                        place.namesForPlaces(content: viewModel.state.content),
                        isOn: choosePlaceBinding(choicePlace: place)
                    )
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                }
                Spacer()
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
                viewModel.state.searchingInfo.searchingRequest.placeForSearch == choicePlace
            },
            set: { selected in
                if selected {
                    viewModel.state.searchingInfo.searchingRequest.placeForSearch = choicePlace
                } else {
                    viewModel.state.searchingInfo.searchingRequest.placeForSearch = nil
                }
            })
    }

    func searchSuggestingNames() -> some View {
        ForEach(viewModel.state.searchingInfo.suggestedSearchingNames, id: \.self) { name in
            Label(name, systemImage: "clock.arrow.circlepath").searchCompletion(name)
        }
    }

    func displayedNameForNavigationTitle() -> String {
        switch viewModel.state.content {
        case .folder(let file):
           return file.displayedName()
        case .tag(let tag):
            return tag.name
        }
    }

    func fileForFileSelectDelegate() -> File? {
        switch viewModel.state.content {
        case .folder(let file):
            return file
        case .tag:
            return nil
        }
    }

    func isFolderInTrashFolder() -> Bool {
        switch viewModel.state.content {
        case .folder(let file):
            return file.hasParent(file: LocalFileManager().trashFolder) == false
        case .tag:
            return false
        }
    }

    func isFolderInLocal() -> Bool {
        switch viewModel.state.content {
        case .folder(let file):
            return file.storageType.isLocal
        case .tag:
            return false
        }
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
