//
//  WebContentViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 23.08.2023.
//

import Foundation

class WebContentViewModel: ObservableObject {
    
    struct State {
        let file: File
        var error: Error?
        var loading = true
        var linkForFilePreview: URL?
    }
    
    @Published
    var state: State
    
    init(file: File) {
        self.state = State(file: file)
    }
    
    func getLinkForPreview() {
        let fileManager = FileManagerFactory.makeFileManager(file: state.file)
        state.loading = true
        if state.file.storageType == .local(LocalStorageData()) {
            self.state.linkForFilePreview = state.file.path
            return
        }
        fileManager.copyToLocalTemporary(files: [state.file]) { result in
            switch result {
            case .success(let urls):
                if let tempURL = urls.first {
                    self.state.linkForFilePreview = tempURL
                    break
                }
            case .failure(let failure):
                self.state.error = failure
            }
        }
        self.state.loading = false
    }
}
