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
        let path = makePathToRootOrElse(file: file)
        client.files.createFolderV2(path: path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(()))
        }
    }
    
    func newNameForCreationOfFolder(at file: File, completion: @escaping (Result<File, Error>) -> Void) {
        var destinationFile = file.makeSubfile(name: R.string.localizable.newFolder.callAsFunction())
        if file == rootFolder {
            destinationFile = File(path: URL(fileURLWithPath: "/\(R.string.localizable.newFolder.callAsFunction())"), storageType: .dropbox(DropboxStorageData()))
        }
        var fileForChanges = destinationFile
        var numberOfFolder = 0
        contents(of: file) { result in
            switch result {
            case .success(let files):
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
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var filesRelocationPaths:  Array<Files.RelocationPath> = []
        for file in files {
            let copyFilePath = makePathToRootOrElse(file: file)
            let destinationFile = destination.makeSubfile(name: file.name)
            let destinationPath = makePathToRootOrElse(file: destinationFile)
            filesRelocationPaths.append(Files.RelocationPath(fromPath: copyFilePath, toPath: destinationPath))
        }
        client.files.copyBatchV2(entries: filesRelocationPaths).response { response, error in
            if let error = error {
                print(error)
                completion(.failure(Error(dropboxError: error)))
                return
            }
        }
        completion(.success(.finished))
    }
    
    func copy(file: File, destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {
    }
    
    func move(files: [File], destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var filesRelocationPaths:  Array<Files.RelocationPath> = []
        for file in files {
            let copyFilePath = makePathToRootOrElse(file: file)
            let destinationFile = destination.makeSubfile(name: file.name)
            let destinationPath = makePathToRootOrElse(file: destinationFile)
            filesRelocationPaths.append(Files.RelocationPath(fromPath: copyFilePath, toPath: destinationPath))
        }
        client.files.moveBatchV2(entries: filesRelocationPaths).response { response, error in
            if let error = error {
                print(error)
                completion(.failure(Error(dropboxError: error)))
                return
            }
        }
        completion(.success(.finished))
    }
    
    func move(file: File, destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void) {
    }
    
    func moveToTrash(filesToTrash: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        for file in filesToTrash {
            let path = makePathToRootOrElse(file: file)
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
        for file in filesToRestore {
            let path = makePathToRootOrElse(file: file)
            client.files.listRevisions(path: path).response { response, error in
                if let error = error {
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                guard let lastRevision = response?.entries.last else { return }
                client.files.restore(path: path, rev: lastRevision.rev).response { response, error in
                    if let error = error {
                        completion(.failure(Error(dropboxError: error)))
                        return
                    }
                }
            }
        }
        completion(.success(()))
    }
    
    func deleteFile(files: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        for file in files {
            let path = makePathToRootOrElse(file: file)
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
    
    func copyToLocalTemporary(files: [File], conflictResolver: NameConflictResolver, completion: @escaping (Result<[URL], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let group = DispatchGroup()
        var destinationFileURLs: [URL] = []
        for file in files {
            group.enter()
            let copyFilePath = makePathToRootOrElse(file: file)
            let destinationFileURL = SystemFileManger.default.temporaryDirectory.appending(component: file.name)
            let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
                return destinationFileURL
            }
            client.files.download(path: copyFilePath, destination: destination).response { response, error in
                if let error = error {
                    defer { group.leave() }
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                if let result = response {
                    defer { group.leave() }
                    destinationFileURLs.append(result.1)
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion(.success(destinationFileURLs))
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
        var filesCommitInfo = [URL : Files.CommitInfo]()
        
        for file in files {
            let fileUrl: URL = file.path
            let uploadToPath = destination.makeSubfile(name: file.name).path.path
            filesCommitInfo[fileUrl] = Files.CommitInfo(path: uploadToPath, mode: Files.WriteMode.overwrite)
        }
        
        client.files.batchUploadFiles(
            fileUrlsToCommitInfo: filesCommitInfo,
            responseBlock: { (uploadResults: [URL: Files.UploadSessionFinishBatchResultEntry]?,
                              finishBatchRequestError: CallError<Async.PollError>?,
                              fileUrlsToRequestErrors: [URL: CallError<Async.PollError>]) -> Void in
                
                if let uploadResults = uploadResults {
                    for (clientSideFileUrl, result) in uploadResults {
                        switch(result) {
                        case .success(let metadata):
                            let dropboxFilePath = metadata.pathDisplay!
                            print("Upload \(clientSideFileUrl.absoluteString) to \(dropboxFilePath) succeeded")
                        case .failure(let error):
                            print("Upload \(clientSideFileUrl.absoluteString) failed: \(error.description)")
                        }
                    }
                }
                else if let finishBatchRequestError = finishBatchRequestError {
                    print("Error uploading file: possible error on Dropbox server: \(finishBatchRequestError)")
                } else if fileUrlsToRequestErrors.count > 0 {
                    print("Error uploading file: \(fileUrlsToRequestErrors)")
                }
            })
    }
}

// MARK: - Private

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
                        var fileInFolder = File(
                            path: URL(fileURLWithPath: deletedMetadata.pathLower!),
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
