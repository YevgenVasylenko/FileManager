//
//  FolderViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 06.07.2023.
//

import Foundation

struct State {
    var loading: Bool = true
    var files: [File] = []
    var error: Error?
}

//protocol FolderViewModel: ObservableObject {
//    var state: State { get }
//    func load()
//}

class FolderViewModelImpl: ObservableObject {
    private let fileManager = LocalFileManager(fileManagerRootPath: LocalFileMangerRootPath())
    let file: File
    
    private lazy var folderMonitor = FolderMonitor(url: self.file.path)
    
    
   convenience init(file: File) {
       self.init(file: file, state: State())
    }
    
     init(file: File, state: State) {
        self.file = file
        self.state = state
         
         folderMonitor.folderDidChange = { [weak self] in
             self?.load()
         }
    }
    
    @Published
    private(set) var state = State()
    
    func load() {
        folderMonitor.startMonitoring()
        print(file.path.lastPathComponent)
        state.loading = true
        fileManager.contents(of: file) { result in
            switch result {
            case .success(let files):
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [self] in
                    self.state.files = files
                }
            case .failure(let failure):
                state.error = failure
            }
            state.loading = false
        }
    }
    
}

//class FolderViewModelStub: FolderViewModel, ObservableObject {
//    var state: State
//    func load() {}
//    
//    init(state: State) {
//        self.state = state
//    }
//}
