//
//  FileInfoViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 28.08.2023.
//

import Foundation


struct FileAttributes {
    let size: Double
    let createdDate: Date?
    let modifiedDate: Date?
}

class FileInfoViewModel: ObservableObject {
    
    struct State {
        let file: File
        var error: Error?
        var isLoading = true
        var fileAttributes: FileAttributes?
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
                self.state.fileAttributes = attributes
            case .failure(let failure):
                self.state.error = failure
            }
        }
    }
}
