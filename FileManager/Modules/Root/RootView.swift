//
//  RootView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct RootView: View {
    let fileSelectDelegate: FileSelectDelegate?
    
    @StateObject
    private var viewModel: RootViewModel
    
    init(fileSelectDelegate: FileSelectDelegate? = nil) {
        self.fileSelectDelegate = fileSelectDelegate
        self._viewModel = StateObject(wrappedValue: RootViewModel())
//        self.viewModel = RootViewModel()
    }
    
    var body: some View {
        NavigationSplitView {
            List(viewModel.state.files, id: \.self, selection: $viewModel.state.selectedFile) { file in
                dataSourceSelectionButton(file: file)
            }
            .onChange(of: viewModel.state.selectedFile) { newValue in
                viewModel.state.detailNavigationStack = NavigationPath()
            }
        } detail: {
            if viewModel.isLoggedToCloud() || viewModel.state.selectedFile?.storageType.isLocal ?? true {
                NavigationStack(path: $viewModel.state.detailNavigationStack) {
                    folderView(file: viewModel.state.selectedFile ?? viewModel.state.files[0])
                        .navigationDestination(for: File.self) { file in
                            folderView(file: file)
                        }
                        .id(viewModel.state.selectedFile)
                }
            } else {
                connectionButton()
                    .toolbar(.hidden)
            }
        }
        .onOpenURL { url in
            DropboxLoginManager.openUrl(url: url)
        }
    }
}

// MARK: - Private

private extension RootView {
    
    private func folderView(file: File) -> some View {
        FolderView(
            file: file,
            fileSelectDelegate: fileSelectDelegate
        )
    }
}

private extension RootView {
    func dataSourceSelectionButton(file: File) -> some View {
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
                    Button(R.string.localizable.disconnect.callAsFunction(), role: .destructive) {
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
            Label(R.string.localizable.connect.callAsFunction(), systemImage: "plus")
                .padding()
        }
        .font(.title)
        .buttonStyle(.borderedProminent)
    }
    
    func cancelButtonForFolderSelection(chooseAction: @escaping () -> Void) -> some View {
        Group {
            if fileSelectDelegate != nil {
                Button(R.string.localizable.cancel.callAsFunction()) {
                    chooseAction()
                }
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
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
