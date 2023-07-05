//
//  ContentView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct ContentView: View {
    let files: [File]
    
    var body: some View {
        NavigationSplitView {
            SideBarView()
        } detail: {
            FolderView(files: files)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var files: [File] = []
    static var previews: some View {
        ContentView(files: files)
    }
}
