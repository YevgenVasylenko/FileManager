//
//  FolderGridViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 19.09.2023.
//

import Foundation

class FolderGridViewModel: ObservableObject {
    struct State {
        var files: [File]
    }
    
    @Published
    var state: State
    
    init(files: [File]) {
        self.state = State(files: files)
    }
}

