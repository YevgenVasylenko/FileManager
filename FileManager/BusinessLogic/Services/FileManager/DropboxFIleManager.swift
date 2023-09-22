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
                    self.correctFolderPath(file: &fileInFolder)
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
        var destinationFile: File
        if file == rootFolder {
            destinationFile = File(path: URL(fileURLWithPath: "/\(newFolderName)"), storageType: .dropbox(DropboxStorageData()))
        } else {
            destinationFile = file.makeSubfile(name: newFolderName, isDirectory: true)
        }
        self.correctFolderPath(file: &destinationFile)
        contents(of: file) { result in
            switch result {
            case .success(let files):
                var fileForChanges = destinationFile
                var numberOfFolder = 0
                repeat {
                    let suffixToName = numberOfFolder == 0 ? "" : " \(numberOfFolder)"
                    let newName = destinationFile.name + suffixToName
                    fileForChanges = fileForChanges.rename(name: newName)
                    self.correctFolderPath(file: &fileForChanges)
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
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        if files.count == 1 {
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
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        if files.count == 1 {
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
    
    func getFileAttributes(file: File, completion: @escaping (Result<FileAttributes, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        if file.folderAffiliation == .system(.trash) {
            return
        }
        var newFile = file
        correctFolderPath(file: &newFile)
        client.files.getMetadata(path: newFile.path.path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            if let result = response {
                switch result {
                case let fileMetadata as Files.FileMetadata:
                    self.getSizeOfFile(file: file) { result in
                        switch result {
                        case .success(let sizeOfFile):
                            completion(.success(FileAttributes(
                                size: sizeOfFile,
                                createdDate: fileMetadata.serverModified,
                                modifiedDate: fileMetadata.clientModified
                            )))
                        case .failure(let error):
                            completion(.failure(Error(error: error)))
                        }
                    }
                case _ as Files.FolderMetadata:
                    self.getSizeOfFolder(file: file) { result in
                        switch result {
                        case .success(let sizeOfFolder):
                            completion(.success(FileAttributes(
                                size: sizeOfFolder,
                                createdDate: nil,
                                modifiedDate: nil
                            )))
                        case .failure(let error):
                            completion(.failure(Error(error: error)))
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}

extension DropboxFileManager: LocalTemporaryFolderConnector {
    
    func copyToLocalTemporary(
        files: [File],
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
            let destinationFile = File(
                path: SystemFileManger.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString, isDirectory: true),
                storageType: .local(LocalStorageData())
            )
            FileManagerCommutator().createFolder(at: destinationFile) { result in
                switch result {
                case .success:
                    break
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
            let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
                return destinationFile.makeSubfile(name: file.name).path
            }
            client.files.download(path: copyFilePath, overwrite: true, destination: destination).response { response, error in
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
    
    func getLocalFileURL(file: File, completion: @escaping (Result<URL, Error>) -> Void) {
        copyToLocalTemporary(files: [file]) { result in
            switch result {
            case .success(let urls):
                if let tempURL = urls.first {
                    completion(.success(tempURL))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Private

private extension DropboxFileManager {
    
    func correctFolderPath(file: inout File) {
//    TO DO make extension for file
        if file.path.pathExtension == "" {
            file.path = file.path.appendingPathExtension(for: .folder)
        }
    }
    
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
                        self.correctFolderPath(file: &fileInFolder)
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
            self.correctFolderPath(file: &trashFolder)
            files.append(self.trashFolder)
        }
    }
    
    func getSizeOfFile(file: File, completion: @escaping (Result<Double, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = dropboxPath(file: file)
        
        client.files.getMetadata(path: path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            if let result = response {
                switch result {
                case let fileMetadata as Files.FileMetadata:
                    completion(.success(Double(fileMetadata.size)))
                default:
                    break
                }
            }
        }
    }
    
    func getSizeOfFolder(file: File, completion: @escaping (Result<Double, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = dropboxPath(file: file)
        var newFile = file
        correctFolderPath(file: &newFile)
        
        client.files.listFolder(path: path, recursive: true).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            if let result = response {
                var size = 0.0
                for fileInResult in result.entries {
                    switch fileInResult {
                    case let metaDataSize as Files.FileMetadata:
                        size += Double(metaDataSize.size)
                    default:
                        continue
                    }
                }
                completion(.success(size))
            }
        }
    }
}
