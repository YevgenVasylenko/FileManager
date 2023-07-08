//
//  ContentView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct ContentView: View {
    let file: File
    
    init(file: File = LocalFileManager().rootFolder) {
        self.file = file
    }
    
    var body: some View {
        NavigationSplitView {
            SideBarView()
        } detail: {
            FolderView(viewModel: FolderViewModelImpl(file: file))
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
