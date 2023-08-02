//
//  DropboxFIleManager.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 31.07.2023.
//

import Foundation
import SwiftyDropbox

final class DropboxFileManager {
    private(set) lazy var rootFolder = File(path: URL(fileURLWithPath: ""),
                                            storageType: .dropbox(DropboxStorageData()))
    
}

extension DropboxFileManager: FileManager {
    
    func contents(of file: File, completion: @escaping (Result<[File], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        let path = file == rootFolder ? "" : file.path.path
        client.files.listFolder(path: path).response { response, error in
            if let error = error {
                completion(.failure(Error(error: error)))
                return
            }
            var files: [File] = []
            if let result = response {
                for fileInResult in result.entries {
                    let fileInFolder = File(path: URL(fileURLWithPath: fileInResult.pathLower!),
                                            storageType: .dropbox(DropboxStorageData()))
                    files.append(fileInFolder)
                }
            }
            completion(.success(files))
        }
    }
    
    func createFolder(at file: File, completion: @escaping (Result<Void, Error>) -> Void) {
            
    }
    
    func rename(file: File, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
    }
    
    func copy(files: [File], destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {

    }
    
    func copy(file: File, destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {
        
    }
    
    func move(files: [File], destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {
        
    }
    
    func move(file: File, destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {
        
    }
    
    func moveToTrash(filesToTrash: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        
    }
    
    func deleteFile(files: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        
    }
    
    
}
