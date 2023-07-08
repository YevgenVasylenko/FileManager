//
//  FileContextMenuModel.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 07.07.2023.
//

import Foundation

struct ConflictResolverImpl: ConflictResolver {
    var mockResult: ConflictNameResult!
    
    func resolve() -> ConflictNameResult {
        mockResult
    }
}

class FileContextMenuViewModel: ObservableObject {
    private let fileManager = LocalFileManager(fileManagerRootPath: LocalFileMangerRootPath())
    private let file: File
    
    init(file: File) {
        self.file = file
    }
    
    
    @Published
    private(set) var state = State()
    
//    func rename() {
//        fileManager.moveFile(fileToCopy: file, destination: file.rename(name: <#T##String#>), conflictResolver: , completion: <#T##(Result<Void, Error>) -> Void#>)
//    }
    
    func delete() {
        fileManager.deleteFile(file: file) { result in
            switch result {
            case .success:
                state.loading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [self] in
                    state.loading = false
                        }
            case .failure(let failure):
                state.error = failure
            }
        }
    }
}
