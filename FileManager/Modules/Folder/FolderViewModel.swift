//
//  FolderViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 06.07.2023.
//

import Foundation

//protocol FolderViewModel: ObservableObject {
//    var state: State { get }
//    func load()
//}

class FolderViewModelImpl: ObservableObject {
    
    struct State {
        var folder: File
        var files: [File] = []
        var loading: Bool = true
        var error: Error?
    }
    
    private let fileManager = LocalFileManager(fileManagerRootPath: LocalFileMangerRootPath())
    private let file: File
    
    private lazy var folderMonitor = FolderMonitor(url: self.file.path)
    
    init(file: File, state: State) {
       self.file = file
       self.state = state
        
        folderMonitor.folderDidChange = { [weak self] in
            self?.load()
        }
   }
    
   convenience init(file: File) {
       self.init(file: file, state: State(folder: file))
    }
    
    @Published
    private(set) var state: State
    
    func load() {
        folderMonitor.startMonitoring()
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
    
    func createFolder() {
        
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
