//
//  FolderView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FolderView: View {
    @ObservedObject var viewModel: FolderViewModel
    let fileSelectDelegate: FileSelectDelegate?
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    
    init(file: File, fileSelectDelegate: FileSelectDelegate?) {
        viewModel = FolderViewModel(file: file)
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    init(viewModel: FolderViewModel, fileSelectDelegate: FileSelectDelegate?) {
        self.viewModel = viewModel
        self.fileSelectDelegate = fileSelectDelegate
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.state.loading == true {
                    ProgressView()
                }
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.state.files, id: \.self) { file in
                            VStack {
                                NavigationLink {
                                    viewToShow(file: file)
                                } label: {
                                    FileView(file: file)
                                }
                                FileOptionsButtonView(file: file)
                            }
                        }
                        Spacer()
                    }
                }
                createFolderButton()
            }
        }
        .onAppear {
            if EnvironmentUtils.isPreview == false {
                viewModel.load()
            }
        }
        .errorAlert(error: $viewModel.state.error)
        .navigationViewStyle(.stack)
        .buttonStyle(.plain)
        .padding()
        .navigationTitle(viewModel.file.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBar(
            fileActionType: fileSelectDelegate?.type,
            file: viewModel.file,
            chooseAction: {
            fileSelectDelegate?.selected(viewModel.file)
        })
    }
}

private extension FolderView {
    
    func viewToShow(file: File) -> some View {
        Group {
            FolderView(file: file, fileSelectDelegate: fileSelectDelegate)
        }
    }
    
    func createFolderButton() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    viewModel.createFolder()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 70))
                }
                .padding()
            }
        }
    }
}

extension View {
    func navigationBar(
        fileActionType: FileActionType?,
        file: File,
        chooseAction: @escaping () -> Void
    ) -> some View {
        toolbar {
            Button {
                
            } label: {
                Image(systemName: "square.grid.3x3.square")
            }
            if fileActionType == nil {
                Button("Choose") {
                }
            }
            
            Button {
                
            } label: {
                Image(systemName: "magnifyingglass")
            }
            
            if let fileActionType = fileActionType {
                Button(nameOfActionSelection(fileActionType: fileActionType)) {
                    chooseAction()
                }
            }
        }
    }
    
    func nameOfActionSelection(fileActionType: FileActionType) -> String {
        switch fileActionType {
        case .copy:
            return R.string.localizable.copy_to.callAsFunction()
        case .move:
            return R.string.localizable.move_to.callAsFunction()
        }
    }
}

struct FolderView_Previews: PreviewProvider {
    static var previews: some View {
        FolderView(
            viewModel: FolderViewModel(
                file: PreviewFiles.rootFolder,
                state: .init(folder: PreviewFiles.rootFolder,
                             files: PreviewFiles.filesInTrash)), fileSelectDelegate: nil)
    }
}
