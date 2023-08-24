//
//  WebContentView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 21.08.2023.
//

import SwiftUI

struct WebContentView: View {
    
    @ObservedObject var viewModel: WebContentViewModel
    
    init(file: File) {
        self.viewModel = WebContentViewModel(file: file)
    }
    
    var body: some View {
        Group {
            if let path = viewModel.state.linkForFilePreview {
                WebView(url: path)
                    .navigationTitle(viewModel.state.file.displayedName())
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            viewModel.getLinkForPreview()
        }
    }
}
//
//struct WebView_Previews: PreviewProvider {
//    let file = File(path: SystemFileManger.default.temporaryDirectory.appendingPathComponent("word.docx"), storageType: .local(LocalStorageData()))
//    SystemFileManger.default.createFile(atPath: file.path , contents: nil)
//    static var previews: some View {
//        WebContentView(file: self.file)
//    }
//}
