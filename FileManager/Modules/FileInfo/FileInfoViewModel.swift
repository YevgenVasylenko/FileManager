//
//  FileInfoViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 28.08.2023.
//

import Foundation

final class FileInfoViewModel: ObservableObject {
    
    struct State {
        var file: File
        var error: Error?
        var isLoading = true
    }
    
    private var fileManagerCommutator = FileManagerCommutator()
    
    @Published
    var state: State
    
    init(file: File) {
        self.state = State(file: file)
        info(file: file)
    }
    
    func info(file: File) {
        fileManagerCommutator.getFileAttributes(file: file) { result in
            switch result {
            case .success(let attributes):
                self.state.file.attributes = attributes
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
}
