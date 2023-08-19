//
//  DropboxFIleManager.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 31.07.2023.
//

import Foundation
import SwiftyDropbox

final class DropboxFileManager {
    enum Constants {
        static let trash = "trash"
    }
    
    private(set) lazy var rootFolder = File(path: URL(fileURLWithPath: ""),
                                            storageType: .dropbox(DropboxStorageData()))
    private(set) lazy var trashFolder = File(
        path: URL(fileURLWithPath: "/\(Constants.trash)"),
        storageType: .dropbox(DropboxStorageData())
    )
}

extension DropboxFileManager: FileManager {
    
    func contents(of file: File, completion: @escaping (Result<[File], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = dropboxPath(file: file)
        
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
                        path: URL(fileURLWithPath: fileInResult.pathDisplay!),
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
        let path = dropboxPath(file: file)
        client.files.createFolderV2(path: path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(()))
        }
    }
    
    func newNameForCreationOfFolder(
        at file: File,
        newFolderName: String,
        completion: @escaping (Result<File, Error>) -> Void
    ) {
        let destinationFile: File
        if file == rootFolder {
            destinationFile = File(path: URL(fileURLWithPath: "/\(newFolderName)"), storageType: .dropbox(DropboxStorageData()))
        } else {
            destinationFile = file.makeSubfile(name: newFolderName)
        }
        contents(of: file) { result in
            switch result {
            case .success(let files):
                var fileForChanges = destinationFile
                var numberOfFolder = 0
                repeat {
                    let suffixToName = numberOfFolder == 0 ? "" : " \(numberOfFolder)"
                    let newName = destinationFile.name + suffixToName
                    fileForChanges = fileForChanges.rename(name: newName)
                    numberOfFolder += 1
                } while files.contains(fileForChanges)
                completion(.success(fileForChanges))
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
    }

    func rename(file: File, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let renamedFilePath = file.rename(name: newName).path.path
        let path = dropboxPath(file: file)
        client.files.moveV2(fromPath: path, toPath: renamedFilePath).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(()))
        }
    }
    
    func copy(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        isForOneFile: Bool,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        if isForOneFile {
            guard let oneFile = files.last else { return }
            copyOne(file: oneFile, destination: destination, conflictResolver: conflictResolver, completion: completion)
        } else {
            copyBatch(files: files, destination: destination, conflictResolver: conflictResolver, completion: completion)
        }
    }

    func move(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        isForOneFile: Bool,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        if isForOneFile {
            guard let oneFile = files.last else { return }
            moveOne(file: oneFile, destination: destination, conflictResolver: conflictResolver, completion: completion)
        } else {
            moveBatch(files: files, destination: destination, conflictResolver: conflictResolver, completion: completion)
        }
    }
    
    func moveToTrash(filesToTrash: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        for file in filesToTrash {
            let path = dropboxPath(file: file)
            client.files.deleteV2(path: path).response { response, error in
                if let error = error {
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    func restoreFromTrash(filesToRestore: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let group = DispatchGroup()
        for file in filesToRestore {
            group.enter()
            let path = dropboxPath(file: file)
            client.files.listRevisions(path: path).response { response, error in
                if let error = error {
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                guard let lastRevision = response?.entries.last else { return }
                client.files.restore(path: path, rev: lastRevision.rev).response { response, error in
                    defer { group.leave() }
                    if let error = error {
                        completion(.failure(Error(dropboxError: error)))
                        return
                    }
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion(.success(()))
        }
    }
    
    func deleteFile(files: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        for file in files {
            let path = dropboxPath(file: file)
            client.files.permanentlyDelete(path: path).response { response, error in
                if let error = error {
                    print(error)
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    func cleanTrashFolder(fileForFileManager: File, completion: @escaping (Result<Void, Error>) -> Void) {
        contents(of: trashFolder) { result in
            switch result {
            case .success(let files):
                self.deleteFile(files: files, completion: completion)
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
    }
    
    func makeFolderMonitor(file: File) -> FolderMonitor? {
        return DropboxFolderMonitor(url: file.path)
    }
}

extension DropboxFileManager: LocalTemporaryFolderConnector {
    
    func copyToLocalTemporary(
        files: [File],
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<[URL], Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let group = DispatchGroup()
        var destinationFileURLs: [URL] = []
        var lastError: Error?
        for file in files {
            group.enter()
            let copyFilePath = dropboxPath(file: file)
            let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
                return SystemFileManger.default.temporaryDirectory.appending(component: file.name)
            }
            client.files.download(path: copyFilePath, destination: destination).response { response, error in
                defer { group.leave() }
                if let error = error {
                    lastError = Error(dropboxError: error)
                    return
                }
                if let result = response {
                    destinationFileURLs.append(result.1)
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            if let error = lastError {
                completion(.failure(error))
            } else {
                completion(.success(destinationFileURLs))
            }
        }
    }
    
    func saveFromLocalTemporary(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        isForOneFile: Bool,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var filesCommitInfo = [URL: Files.CommitInfo]()
        
        for file in files {
            let fileUrl = file.path
            let uploadToPath = destination.makeSubfile(name: file.name).path.path
            filesCommitInfo[fileUrl] = Files.CommitInfo(path: uploadToPath, mode: .overwrite)
        }
        
        client.files.batchUploadFiles(
            fileUrlsToCommitInfo: filesCommitInfo,
            responseBlock: { uploadResults, finishBatchRequestError, fileUrlsToRequestErrors in
                
                if let finishBatchRequestError = finishBatchRequestError {
                    completion(.failure(Error(dropboxError: finishBatchRequestError)))
                    return
                }
                if let error = fileUrlsToRequestErrors.first?.value {
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                completion(.success(.finished))
            })
    }
}

// MARK: - Private

private extension DropboxFileManager {
    
    func copyOne(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let destinationFile = destination.makeSubfile(name: file.name)
        client.files.copyV2(fromPath: file.path.path, toPath: destinationFile.path.path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(.finished))
        }
    }
    
    func copyBatch(files: [File],
                   destination: File,
                   conflictResolver: NameConflictResolver,
                   completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var filesRelocationPaths: [Files.RelocationPath] = []
        for file in files {
            let copyFilePath = dropboxPath(file: file)
            let destinationFile = destination.makeSubfile(name: file.name)
            let destinationPath = dropboxPath(file: destinationFile)
            filesRelocationPaths.append(Files.RelocationPath(fromPath: copyFilePath, toPath: destinationPath))
        }
        client.files.copyBatchV2(entries: filesRelocationPaths).response { response, error in
            if let error = error {
                print(error)
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(.finished))
        }
    }
    
    func moveOne(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let destinationFile = destination.makeSubfile(name: file.name)
        client.files.moveV2(fromPath: file.path.path, toPath: destinationFile.path.path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(.finished))
        }
    }
    
    func moveBatch(files: [File],
                   destination: File,
                   conflictResolver: NameConflictResolver,
                   completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var filesRelocationPaths: [Files.RelocationPath] = []
        for file in files {
            let copyFilePath = dropboxPath(file: file)
            let destinationFile = destination.makeSubfile(name: file.name)
            filesRelocationPaths.append(Files.RelocationPath(fromPath: copyFilePath, toPath: destinationFile.path.path))
        }
        client.files.moveBatchV2(entries: filesRelocationPaths).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(.finished))
        }
    }
    
    func dropboxPath(file: File) -> String {
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
                        var fileInFolder = File(
                            path: URL(fileURLWithPath: deletedMetadata.pathDisplay!),
                            storageType: .dropbox(DropboxStorageData())
                        )
                        fileInFolder.actions = [FileAction.restoreFromTrash]
                        fileInFolder.isDeleted = true
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
            trashFolder.folderAffiliation = .system(.trash)
            files.append(self.trashFolder)
        }
    }
}
