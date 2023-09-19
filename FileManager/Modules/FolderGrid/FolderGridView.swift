//
//  FolderGridView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 18.09.2023.
//

import SwiftUI

struct FolderGridView: View {
    @ObservedObject
    private var viewModel: FolderGridViewModel
    
    private let fileSelectDelegate: FileSelectDelegate?
    private var columns: [GridItem] {
        columnsForView()
    }
    
    init(files: [File], fileSelectDelegate: FileSelectDelegate?) {
        viewModel = FolderGridViewModel(files: files)
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach($viewModel.state.files, id: \.self) { $file in
                
                VStack {
                    NavigationLink {
                        viewToShow(file: file)
                    } label: {
                        FileView(file: file, infoPresented: fileInfoPopoverBinding(for: file))
                    }
                    if fileSelectDelegate == nil {
                        fileActionsMenuView(file: file)
                    } else {
                        Spacer()
                    }
                }
                .disabled(viewModel.isFilesDisabledInFolder(
                    isFolderDestinationChose: fileSelectDelegate, file: file) ||
                          viewModel.state.fileInfoPopover != nil
                )
                .overlay(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                    filesChooseToggle(file: file)
                }
            }
        }
    }
    
    func columnsForView() -> [GridItem] {
        .init(
            repeating: GridItem(.flexible()),
            count: fileSelectDelegate == nil ? 5 : 4
        )
    }
    
    func viewToShow(file: File) -> some View {
        Group {
            if file.isFolder() {
                FolderGridView()
            } else {
                FileContentView(file: file)
            }
        }
    }
}
//
//struct SwiftUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
//}
