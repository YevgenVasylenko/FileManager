//
//  RootView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct RootView: View {
    let file: File
    var fileSelectDelegate: FileSelectDelegate?
    
    init(
        file: File = LocalFileManager().rootFolder,
        fileSelectDelegate: FileSelectDelegate? = nil
    ){
        self.file = file
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        NavigationSplitView {
            SideBarView()
                .navigationBarItems(
                    trailing: cancelButtonForFolderSelection(chooseAction: {
                        fileSelectDelegate?.selected(nil)
                    }))
        } detail: {
            FolderView(file: file, fileSelectDelegate: fileSelectDelegate)
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
