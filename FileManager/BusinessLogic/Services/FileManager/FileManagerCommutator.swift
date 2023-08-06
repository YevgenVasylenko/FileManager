//
//  FileManagerCommutator.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 06.08.2023.
//

import Foundation

final class FileManagerCommutator {
//    private let fileOfAction: File
//    let fileOfDestination: File? = nil
//
//    init(fileOfAction: File) {
//        self.fileOfAction = fileOfAction
//    }
}

extension FileManagerCommutator: FileManager {
    
   func contents(of file: File, completion: @escaping (Result<[File], Error>) -> Void) {
        FileManagerFactory.makeFileManager(file: file).contents(of: file, completion: completion)
    }
    
    func createFolder(at file: File, completion: @escaping (Result<Void, Error>) -> Void) {
        FileManagerFactory.makeFileManager(file: file).createFolder(at: file, completion: completion)
    }
    
    func rename(file: File, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
    }
    
    func copy(files: [File], destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {
        var fileManager: FileManager {
            return FileManagerFactory.makeFileManager(file: files[0])
        }
        if destination.storageType == files.first?.storageType {
            fileManager.copy(files: files, destination: destination, conflictResolver: conflictResolver, completion: completion)
        } else {
            fileManager.send(files: files) { result in
                switch result {
                case .success(let fileToReceivePath):
                    FileManagerFactory.makeFileManager(file: destination).receive(
                        filesToReceive: [File(
                            path: fileToReceivePath,
                            storageType: destination.storageType)],
                            fileToPlace: destination, conflictResolver: conflictResolver
                    )
                case .failure(let error):
                    completion(.failure(Error(error: error)))
                }
            }
        }
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
    
    func send(files: [File], completion: @escaping (Result<URL, Error>) -> Void) {
        
    }
    
    func receive(filesToReceive: [File], fileToPlace: File, conflictResolver: NameConflictResolver) {
        
    }
    
}
