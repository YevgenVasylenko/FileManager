//
//  RootView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct RootView: View {
    let file: File
    let fileSelectDelegate: FileSelectDelegate?
    
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
        } detail: {
            FolderView(file: file, fileSelectDelegate: fileSelectDelegate)
        }
        .padding()
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(file: PreviewFiles.rootFolder)
    }
}
