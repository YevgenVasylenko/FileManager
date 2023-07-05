//
//  FolderView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FolderView: View {
    var files: [File]
    let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    @State private var searchText = ""

    var body: some View {
        NavigationView {
    
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(files, id: \.self) { file in
                        FileView(file: file)
                    }
                }
            }
            .navigationTitle("My Files")
        }
    }
}

struct FolderView_Previews: PreviewProvider {
    static var files: [File] = []
    static var previews: some View {
        FolderView(files: self.files)
        
    }
}


