//
//  FolderViewModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 06.07.2023.
//

import Foundation

class FolderViewModel: ObservableObject {
  
    struct State {
        var folder: File
        var files: [File] = []
        var loading: Bool = true
        var error: Error?
    }
    
    private let fileManager = LocalFileManager(fileManagerRootPath: LocalFileMangerRootPath())
    let file: File
    
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
    var state: State
    
    func load() {
        folderMonitor.startMonitoring()
        state.loading = true
        fileManager.contents(of: file) { result in
            switch result {
            case .success(let files):
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [self] in
                    self.state.files = files
                }
            case .failure(let failure):
                state.error = failure
            }
            state.loading = false
        }
    }
    
    func createFolder() {
        let createdFile = file.makeSubfile(name: "NewFolder")
        state.loading = true
        fileManager.createFolder(at: createdFile) { result in
            switch result {
            case .success:
                break
            case .failure(let failure):
                state.error = failure
            }
            state.loading = false
        }
    }   
}
