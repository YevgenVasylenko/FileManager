//
//  RootView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct DataSource {
    let file: File
    let fileSelectedDelegate: FileSelectDelegate
}

struct RootView: View {
    let file: File
    let fileSelectDelegate: FileSelectDelegate?
    @State private var files: [File] = [LocalFileManager().rootFolder, DropboxFileManager().rootFolder]
    @State private var selectedFile: File?
    
    init(file: File = LocalFileManager().rootFolder, fileSelectDelegate: FileSelectDelegate? = nil) {
        self.file = file
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        NavigationSplitView {
            List(files, id: \.self, selection: $selectedFile) { file in
                dataSourceSelectionButton(file: file)
            }
        } detail: {
            FolderView(file: selectedFile ?? LocalFileManager().rootFolder, fileSelectDelegate: fileSelectDelegate)
                .id(selectedFile)
        }
        .padding()
        .onOpenURL(perform: { url in
            DropboxLoginManager.openUrl(url: url)
        })
    }
}

private extension RootView {
    func dataSourceSelectionButton(file: File) -> some View {
        Button(action: {
            selectedFile = file
        },
               label: {
            Text(file.displayedName())
                .contextMenu {
                    if file.storageType.isDropbox {
                        Button {
                            DropboxLoginManager.login()
                        } label: {
                            Text(R.string.localizable.connect.callAsFunction())
                        }
                        .disabled(DropboxLoginManager.isLogged)
                        
                        Button(R.string.localizable.disconnect.callAsFunction(), role: .destructive) {
                            DropboxLoginManager.logout()
                        }
                        .disabled(!DropboxLoginManager.isLogged)
                    }
                }
        }).tag(file)
            .buttonStyle(.plain)
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
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(file: PreviewFiles.rootFolder)
    }
}
