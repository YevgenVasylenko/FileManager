//
//  ContextMenuViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 09.07.2023.
//

import Foundation

class ContextMenuViewModel: ObservableObject {
    struct State {
        var file: File
    }
    
    private let fileManager = LocalFileManager()
    private let file: File
    
    @Published
    private(set) var state: State
    
    init(file: File) {
        self.file = file
        self.state = State(file: file)
    }
    
    func delete() {
        fileManager.deleteFile(file: file) { result in
            switch result {
            case .success:
                break
            case .failure:
                break
            }
        }
    }
    
//    func clear() {
//        fileManager.contents(of: file) { result in
//            switch result {
//            case .failure(let failure):
//            case .success(let files):
//                for file in files {
//                    fileManager.deleteFile(file: file) { result in
//                        switch result {
//                        case .success:
//                        case .failure(let failure):
//                        }
//                    }
//                }
//
//            }
//        }
//    }
}
