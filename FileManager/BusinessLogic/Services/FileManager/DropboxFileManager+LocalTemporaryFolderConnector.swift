//
//  DropboxFileManager+LocalTemporaryFolderConnector.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 14.01.2024.
//

import Foundation
import SwiftyDropbox

extension DropboxFileManager: LocalTemporaryFolderConnector {

    func copyBatchOfFilesToLocalTemporary(
        files: [File],
        completion: @escaping (Result<[URL], Error>) -> Void
    ) {
        let group = DispatchGroup()
        var destinationFileURLs: [URL] = []
        var lastError: Error?

        for file in files {
            group.enter()
            copyOneFileToLocalTemporary(fileToCopy: file) { result in
                switch result {
                case .success(let url):
                    destinationFileURLs.append(url)
                case .failure(let failure):
                    lastError = failure
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let lastError {
                completion(.failure(lastError))
            } else {
                completion(.success(destinationFileURLs))
            }
        }
    }

    func moveBatchOfFilesToLocalTemporary(files: [File], completion: @escaping (Result<[URL], Error>) -> Void) {
//              Dropbox api doesn't support permanent delete,
//                  so move file with keeping original copy in trash doesn't make sense
        fatalError()
    }

    func saveFilesFromLocalTemporary(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        for file in files {
            saveOneFileFromLocalTemporary(
                file: file,
                destination: destination,
                conflictResolver: conflictResolver,
                completion: completion
            )
        }
    }

    func getLocalFileURL(file: File, completion: @escaping (Result<URL, Error>) -> Void) {
        copyBatchOfFilesToLocalTemporary(files: [file]) { result in
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

private extension DropboxFileManager {

    func copyOneFileToLocalTemporary(
        fileToCopy: File,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let destinationFolder = File(
            path: SystemFileManger.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true),
            storageType: .local
        )
        do {
            try SystemFileManger.default.createDirectory(
                at: destinationFolder.path,
                withIntermediateDirectories: false
            )
        } catch {
            completion(.failure(Error(error: error)))
            return
        }
        if fileToCopy.isFolder() {
            createOrDownloadBatchOfFilesInLocal(
                fileToCopy: fileToCopy,
                destinationFile: destinationFolder,
                completion: completion
            )
        } else {
            let destinationFile = destinationFolder.makeSubfile(name: fileToCopy.name)
            downloadDropboxFileToLocal(
                fileToDownload: fileToCopy,
                destinationFile: destinationFile,
                completion: completion
            )
        }
    }

    func createOrDownloadBatchOfFilesInLocal(
        fileToCopy: File,
        destinationFile: File,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        allFilesInDropbox(folder: fileToCopy) { result in
            switch result {
            case .failure(let failure):
                completion(.failure(failure))

            case .success(let files):
                let group = DispatchGroup()
                var destinationFileURL: URL?
                var lastError: Error?
                var isFirstFileInAll = true

                for file in files {
                    group.enter()
                    self.createOrDownloadOneFileInLocal(
                        file: file,
                        destinationFile: destinationFile
                    ) { result in
                            switch result {
                            case .success(let file):
                                if isFirstFileInAll {
                                    destinationFileURL = file.path
                                    isFirstFileInAll = false
                                }
                            case .failure(let failure):
                                lastError = failure
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    if let lastError {
                        completion(.failure(lastError))
                    } else if let destinationFileURL {
                        completion(.success(destinationFileURL))
                    } else {
                        completion(.failure(.unknown))
                    }
                }
            }
        }
    }

    func createOrDownloadOneFileInLocal(
        file: File,
        destinationFile: File,
        completion: @escaping (Result<File, Error>) -> Void
    ) {
        let destinationFolder = self.destinationFolderForDownloading(
            copyFile: file,
            destination: destinationFile
        )
        if file.isFolder() {
            do {
               try SystemFileManger.default.createDirectory(
                    at: destinationFolder.path,
                    withIntermediateDirectories: true
               )
                completion(.success(destinationFolder))
            } catch {
                completion(.failure(Error(error: error)))
            }
        } else {
            self.downloadDropboxFileToLocal(
                fileToDownload: file,
                destinationFile: destinationFolder
            ) { result in
                    switch result {
                    case .success:
                        completion(.success(destinationFolder))
                    case .failure(let failure):
                        completion(.failure(failure))
                    }
                }
        }
    }

    func downloadDropboxFileToLocal(
        fileToDownload: File,
        destinationFile: File,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let copyFilePath = dropboxPath(file: fileToDownload)
        let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
            return destinationFile.path
        }
        client.files.download(
            path: copyFilePath,
            overwrite: true,
            destination: destination
        ).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            if let result = response {
                completion(.success(result.1))
            }
        }
    }

    func destinationFolderForDownloading(copyFile: File, destination: File) -> File {
        let folderPath = destination.path.appendingPathComponent(copyFile.path.path)
        return File(path: folderPath, storageType: .local)
    }

    func allFilesInDropbox(folder: File, completion: @escaping (Result<[File], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = dropboxPath(file: folder)

        client.files.listFolder(path: path, recursive: true).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            var files: [File] = []

            if let result = response {
                for fileInResult in result.entries {
                    var fileInFolder = File(
                        path: URL(fileURLWithPath: fileInResult.pathDisplay!),
                        storageType: .dropbox
                    )
                    self.correctFolderPath(file: &fileInFolder)
                    fileInFolder = self.updatedFile(file: fileInFolder)
                    files.append(fileInFolder)
                }
            }
            completion(.success(files))
        }
    }

    func saveOneFileFromLocalTemporary(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        if file.isFolder() {
            allFilesIn(folder: file) { result in
                switch result {
                case .failure(let failure):
                    completion(.failure(failure))
                case .success(let files):
                    self.createOrUploadBatchOfFilesInDropbox(
                        files: files,
                        destination: destination,
                        conflictResolver: conflictResolver,
                        completion: completion
                    )
                }
            }
        } else {
            uploadOneFileFromLocalTemporary(
                file: file,
                destination: destination,
                conflictResolver: conflictResolver,
                completion: completion
            )
        }
    }

    func allFilesIn(
        folder: File,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        LocalFileManager().allFilesInFolder(file: folder) { result in
            switch result {
            case .failure(let failure):
                completion(.failure(failure))

            case .success(let files):
                completion(.success(files))
            }
        }
    }

    func createOrUploadBatchOfFilesInDropbox(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let file = files.first else {
            completion(.success(.finished))
            return
        }

        createOrUploadOneFileInDropbox(
            file: file,
            destination: destination,
            conflictResolver: conflictResolver) { [self] result in
                switch result {
                case .failure(let failure):
                    completion(.failure(failure))
                case .success:
                    let files = files.dropFirst()
                    createOrUploadBatchOfFilesInDropbox(
                        files: Array(files),
                        destination: destination,
                        conflictResolver: conflictResolver,
                        completion: completion)
                }
            }
    }

    func createOrUploadOneFileInDropbox(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {

        let destinationFolder = makeDestinationFolderForUpload(file: file, destination: destination)
        
        if file.isFolder() {
            createFolder(at: destinationFolder) { result in
                switch result {
                case .success:
                    completion(.success(.finished))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else {
            uploadOneFileFromLocalTemporary(
                file: file,
                destination: destinationFolder.parentFolder(),
                conflictResolver: conflictResolver,
                completion: completion
            )
        }
    }

    func uploadOneFileFromLocalTemporary(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var filesCommitInfo = [URL: Files.CommitInfo]()
        let fileUrl = file.path
        let uploadToPath = destination.makeSubfile(name: file.name).path.path
        filesCommitInfo[fileUrl] = Files.CommitInfo(path: uploadToPath, mode: .add, autorename: true)

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

    func makeDestinationFolderForUpload(file: File, destination: File) -> File {
        let pathWithoutTemp = file.path.removeTemp()
        let pathWithoutFirst = pathWithoutTemp.removeFirst()
        return File(
            path: destination.path.appendingPathComponent(pathWithoutFirst.path),
            storageType: .dropbox
        )
    }
}
