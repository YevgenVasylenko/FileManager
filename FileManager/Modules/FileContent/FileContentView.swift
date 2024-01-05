//
//  FileContentView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 21.08.2023.
//

import SwiftUI

struct FileContentView: View {
    
    @StateObject
    private var viewModel: FileContentViewModel
    
    @Environment(\.presentationMode)
    private var presentation
    
    init(file: File) {
        self._viewModel = StateObject(wrappedValue: FileContentViewModel(file: file))
    }
    
    var body: some View {
        ZStack {
            if let path = viewModel.state.localFileURL {
                WebView(url: path)
                    .navigationTitle(viewModel.state.file.displayedName())
                    .navigationBarTitleDisplayMode(.inline)
            }
            if viewModel.state.isLoading {
                ProgressView()
            }
        }
        .onAppear {
            viewModel.getLocalFileURL()
        }
        .errorAlert(error: $viewModel.state.error)
        .unreadableFileAlert(
            isShowing: .constant(viewModel.state.file.fileType() == .unknown),
            presentation: presentation
        )
    }
}
