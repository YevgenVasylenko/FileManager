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
    private(set) lazy var trashFolder = File(
        path: URL(fileURLWithPath: "/\(R.string.localizable.trash.callAsFunction())"),
        storageType: .dropbox(DropboxStorageData())
    )
}

extension DropboxFileManager: FileManager {
    
    func contents(of file: File, completion: @escaping (Result<[File], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = makePathToRootOrElse(file: file)
        
        if path == self.trashFolder.path.path {
            contentOfTrashFolder(completion: completion)
            return
        }
        
        client.files.listFolder(path: path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            var files: [File] = []
            self.addTrashFolderToRoot(file: file, files: &files)
            
            if let result = response {
                for fileInResult in result.entries {
                    var fileInFolder = File(
                        path: URL(fileURLWithPath: fileInResult.pathLower!),
                        storageType: .dropbox(DropboxStorageData())
                    )
                    fileInFolder.actions = FileAction.regularFolder
                    files.append(fileInFolder)
                }
            }
            completion(.success(files))
        }
    }
    
    func createFolder(at file: File, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        let path = makePathToRootOrElse(file: file)
        client.files.createFolderV2(path: path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(()))
        }
    }
    
    func rename(file: File, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let renamedFilePath = file.rename(name: newName).path.path
        let path = makePathToRootOrElse(file: file)
        client.files.moveV2(fromPath: path, toPath: renamedFilePath).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(()))
        }
    }
    
    func copy(files: [File], destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {
        guard let file = files.first else {
            completion(.success(.finished))
            return
        }
        copy(file: file, destination: destination, conflictResolver: conflictResolver) { [weak self] result in
            switch result {
            case .success(let result):
                if result == .cancelled {
                    completion(.success(.cancelled))
                    return
                }
                let files = files.dropFirst()
                self?.copy(files: Array(files), destination: destination, conflictResolver: conflictResolver, completion: completion)
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
    }
    
    func copy(file: File, destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let copyFilePath = makePathToRootOrElse(file: file)
        let destinationFile = destination.makeSubfile(name: file.name)
        
        let destinationPath = makePathToRootOrElse(file: destinationFile)
        
            client.files.copyV2(fromPath: copyFilePath, toPath: destinationPath).response { response, error in
                if let error = error {
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                completion(.success(.finished))
            }
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
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let file = File(path: files[0].path, storageType: files[0].storageType)
        let copyFilePath = makePathToRootOrElse(file: file)
        let destinationFile = SystemFileManger.default.temporaryDirectory.appending(component: file.name)
        let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
            return destinationFile
        }
        client.files.download(path: copyFilePath, destination: destination).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(destinationFile))
        }
    }
    
    func receive(filesToReceive: [File], fileToPlace: File, conflictResolver: NameConflictResolver) {
        
    }
}

private extension DropboxFileManager {
    func makePathToRootOrElse(file: File) -> String {
        return file == rootFolder ? "" : file.path.path
    }
    
    func contentOfTrashFolder(completion: @escaping (Result<[File], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        client.files.listFolder(path: "", recursive: true, includeDeleted: true).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            var files: [File] = []
            if let result = response {
                for fileInResult in result.entries {
                    switch fileInResult {
                    case let deletedMetadata as Files.DeletedMetadata:
                        let fileInFolder = File(
                            path: URL(fileURLWithPath: deletedMetadata.pathLower!),
                            storageType: .dropbox(DropboxStorageData())
                        )
                        files.append(fileInFolder)
                    default:
                        continue
                    }
                }
            }
            completion(.success(files))
        }
    }
    
    func addTrashFolderToRoot(file: File, files: inout [File]) {
        if file == self.rootFolder {
            files.append(self.trashFolder)
        }
    }
}
