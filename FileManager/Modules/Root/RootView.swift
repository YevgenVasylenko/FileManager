//
//  RootView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct RootView: View {
    let fileSelectDelegate: FileSelectDelegate?
    
    @ObservedObject
    private var viewModel: RootViewModel
    
    init(fileSelectDelegate: FileSelectDelegate? = nil) {
        self.fileSelectDelegate = fileSelectDelegate
        self.viewModel = RootViewModel()
    }
    
    var body: some View {
        NavigationSplitView {
            List(viewModel.files, id: \.self, selection: $viewModel.state.selectedFile) { file in
                dataSourceSelectionButton(file: file)
            }
        } detail: {
            if viewModel.isLoggedToCloud() || viewModel.state.selectedFile?.storageType.isLocal ?? true {
                FolderView(
                    file: viewModel.state.selectedFile ?? LocalFileManager().rootFolder,
                    fileSelectDelegate: fileSelectDelegate
                )
                    .id(viewModel.state.selectedFile)
            } else {
                connectionButton()
                    .toolbar(.hidden)
            }
        }
        .listStyle(.plain)
        Spacer()
        .onOpenURL(perform: { url in
            DropboxLoginManager.openUrl(url: url)
        })
        .onAppear() {
            viewModel.reloadLoggedState()
        }
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
                }))
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
