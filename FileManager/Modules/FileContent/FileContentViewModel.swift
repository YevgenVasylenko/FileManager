//
//  FileContentViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 23.08.2023.
//

import Foundation

final class FileContentViewModel: ObservableObject {
    
    struct State {
        var file: File?
        var error: Error?
        var isLoading = true
        var localFileURL: URL?
    }
    
    private var fileManagerCommutator = FileManagerCommutator()

    @Published
    var state: State
    
    init(file: File) {
        self.state = State(file: file)
    }
    
    func getLocalFileURL() {
        state.isLoading = true
        guard let file = state.file else { return }
        fileManagerCommutator.getLocalFileURL(file: file) { [self] result in
            switch result {
            case .success(let linkInLocal):
                self.state.localFileURL = linkInLocal
            case .failure(let failure):
                self.state.error = failure
            }
            self.state.isLoading = false
        }
    }
}
