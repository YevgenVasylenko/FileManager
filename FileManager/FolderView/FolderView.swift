//
//  FolderView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FolderView: View {
    @ObservedObject var viewModel: FolderViewModelImpl
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(file: File) {
        viewModel = FolderViewModelImpl(file: file)
    }
    
    init(viewModel: FolderViewModelImpl) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            
            ScrollView {
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.state.files, id: \.self) { file in
                        
                        NavigationLink {
                            viewToShow(file: file)
                        } label: {
                            FileView(file: file)
                        }
                    }
                    .navigationTitle(viewModel.file.name)
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
        .navigationViewStyle(.stack)
        .padding()
    }
    
    func viewToShow(file: File) -> some View {
        Group {
            if viewModel.state.loading == true {
                ProgressView()
            }
            if viewModel.state.error != nil {
                Text("error")
            }
            FolderView(viewModel: FolderViewModelImpl(file: file))
        }
    }
}

struct FolderView_Previews: PreviewProvider {
    static let fileManager = LocalFileManager(fileManagerRootPath: LocalFileMangerRootPath())
    static var documentsFolder = fileManager.rootFolder

    static var previews: some View {
        FolderView(viewModel: FolderViewModelImpl(file: documentsFolder))
    }
}


