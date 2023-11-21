//
//  RootView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct RootView: View {
    private let fileSelectDelegate: FileSelectDelegate?
    
    @StateObject
    private var viewModel: RootViewModel
    
    init(fileSelectDelegate: FileSelectDelegate? = nil) {
        self.fileSelectDelegate = fileSelectDelegate
        self._viewModel = StateObject(wrappedValue: RootViewModel())
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                sidebarStorageSection()
                sidebarTagsSection()
            }
            .listStyle(.sidebar)
        } detail: {
            if viewModel.isShouldConnectSelectedStorage() {
                NavigationStack(path: $viewModel.state.detailNavigationStack) {
                    rootDetailView()
                }
            } else {
                connectionButton()
                    .toolbar(.hidden)
            }
        }
        .onOpenURL { url in
            DropboxLoginManager.openUrl(url: url)
        }
        .renamePopover(viewModel: viewModel, newName: $viewModel.state.newNameForTag)
        .errorAlert(error: $viewModel.state.error)
    }
}

// MARK: - Private

private extension RootView {
    
    func folderView(file: File) -> some View {
        FolderView(
            file: file,
            fileSelectDelegate: fileSelectDelegate
        )
        .id(file)
    }
    
    @ViewBuilder
    func rootDetailView() -> some View {
        if let selectedStorage = viewModel.state.selectedStorage {
            folderView(file: selectedStorage)
                .navigationDestination(for: File.self) { file in
                    if file.isFolder() {
                        folderView(file: file)
                    } else {
                        FileContentView(file: file)
                    }
                }
        }
    }
}

private extension RootView {
    func storageListItem(file: File) -> some View {
        Label(title: {
            Spacer()
                .frame(width: 10)
            Text(file.displayedName())
                .font(.headline)
        }, icon: {
            Image(imageNameForSource(file: file))
        }).buttonStyle(.plain)
            .padding()
            .contextMenu {
                if !file.storageType.isLocal {
                    Button(R.string.localizable.disconnect(), role: .destructive) {
                        viewModel.logoutFromCloud()
                    }
                    .disabled(!viewModel.isLoggedToCloud())
                }
            }
            .navigationBarItems(
                trailing: cancelButtonForFolderSelection(chooseAction: {
                    fileSelectDelegate?.selected(nil)
                })
            )
    }
    
    func connectionButton() -> some View {
        Button {
            viewModel.loggingToCloud()
        } label: {
            Label(R.string.localizable.connect(), systemImage: "plus")
                .padding()
        }
        .font(.title)
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    func cancelButtonForFolderSelection(chooseAction: @escaping () -> Void) -> some View {
        if fileSelectDelegate != nil {
            Button(R.string.localizable.cancel()) {
                chooseAction()
            }
        }
    }
    
    func imageNameForSource(file: File) -> String {
        switch file.storageType {
        case .dropbox:
            return R.image.dropbox.name
        case .local:
            return R.image.folder.name
        }
    }

    @ViewBuilder
    func sidebarStorageSection() -> some View {
        Section {
            List(viewModel.state.storages, id: \.self, selection: $viewModel.state.selectedStorage) { file in
                storageListItem(file: file)
            }
        } header: {
            Text(R.string.localizable.places())
        }
        .scaledToFit()
    }

    @ViewBuilder
    func sidebarTagsSection() -> some View {
        Section {
            List(viewModel.state.tags, id: \.self, selection: $viewModel.state.selectedTag) { tag in
                tagsListItem(tag: tag)
            }
        } header: {
            Text(R.string.localizable.tags())
        }
        .scaledToFit()
    }

    @ViewBuilder
    func tagsListItem(tag: Tag) -> some View {
        Label {
            Text(tag.name)
        } icon: {
            Image(systemName: "circle.fill")
                .foregroundColor(Color(uiColor: UIColor(rgb: tag.color?.rawValue ?? 0x000000)))
        }
        .contextMenu {
            tagsListItemContextMenu(tag: tag)
        }
    }

    @ViewBuilder
    func tagsListItemContextMenu(tag: Tag) -> some View {
        Button(role: .destructive) {
            viewModel.deleteTagFromList(tag: tag)
        } label: {
            Label("\(R.string.localizable.delete()) «\(tag.name)»", systemImage: "xmark")
        }

        Button {
            viewModel.state.tagForRename = tag
        } label: {
            Label("\(R.string.localizable.rename()) «\(tag.name)»", systemImage: "pencil")
        }
    }
}

private extension View {
    func renamePopover(viewModel: RootViewModel, newName: Binding<String>) -> some View {
        alert(
            R.string.localizable.renamePopupTitle()
            + (viewModel.state.tagForRename?.name ?? ""),
                     isPresented: .constant(viewModel.state.tagForRename != nil),
                     actions: {
            TextField(R.string.localizable.new_name(),
                      text: newName)
                .padding()
                .interactiveDismissDisabled()
                .autocorrectionDisabled()
            HStack {
                Button(R.string.localizable.rename()) {
                    guard let tag = viewModel.state.tagForRename else { return }
                    viewModel.renameTag(tag: tag, newName: newName.wrappedValue)
                    newName.wrappedValue = ""
                }
                Spacer()
                Button(R.string.localizable.cancel()) {
                    viewModel.state.tagForRename = nil
                    newName.wrappedValue = ""
                }
            }
            .padding()
        })
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}

