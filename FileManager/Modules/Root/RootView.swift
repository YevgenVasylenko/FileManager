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
    var fileSelectDelegate: FileSelectDelegate?
    @State private var files: [File] = [LocalFileManager().rootFolder, LocalFileManager().trashFolder, LocalFileManager().downloadsFolder]
    @State private var selectedFile: File?
    
    init(
        file: File = LocalFileManager().rootFolder,
        fileSelectDelegate: FileSelectDelegate? = nil
    ){
        self.file = file
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        NavigationSplitView {
            List(files, id: \.self, selection: $selectedFile) { file in
                           Text(file.name).tag(file)
//                NavigationLink(value: file) {
//                    Text(file.name).tag(file)
//                }
            }
            .navigationBarItems(
                trailing: cancelButtonForFolderSelection(chooseAction: {
                    fileSelectDelegate?.selected(nil)
                }))
        } detail: {
            FolderView(file: selectedFile ?? LocalFileManager().rootFolder, fileSelectDelegate: fileSelectDelegate)
                .id(selectedFile)
        }
        .padding()
        
    }
    
}

private extension RootView {
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
