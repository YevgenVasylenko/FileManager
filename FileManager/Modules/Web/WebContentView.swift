//
//  WebContentView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 21.08.2023.
//

import SwiftUI

struct WebContentView: View {

    @State private var isPresentWebView = true
    let path: URL
    
    var body: some View {

        NavigationStack {
            
            WebView(url: path)
            
                .ignoresSafeArea()
                .navigationTitle("file.displayedName()")
                .navigationBarTitleDisplayMode(.inline)
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
