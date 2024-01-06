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
    
    @Environment(\.dismiss)
    private var dismiss
    
    init(file: File) {
        self._viewModel = StateObject(wrappedValue: FileContentViewModel(file: file))
    }
    
    var body: some View {
        ZStack {
            if let path = viewModel.state.localFileURL {
                WebView(url: path)
                    .navigationTitle(viewModel.state.file?.displayedName() ?? "")
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
    }
}
