//
//  LocalFileManager+LocalTemporaryFolderConnector.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 18.01.2024.
//

import Foundation

extension LocalFileManager: LocalTemporaryFolderConnector {

    func copyBatchOfFilesToLocalTemporary(files: [File], completion: @escaping (Result<[URL], Error>) -> Void) {
        let conflictResolve = NameConflictResolverError()
        var destinationFileURLs: [URL] = []
        var error: Error?

        DispatchGroup.perform(
            value: files,
            action: { [self] file, completion in
                let temporaryStorage = File.localUUIDTemporaryFolder()
                createFolder(at: temporaryStorage) { _ in
                }
                let destinationPath = temporaryStorage.makeSubfile(name: file.name, isDirectory: file.isFolder()).path
                copy(file: file, destination: temporaryStorage, conflictResolver: conflictResolve) { result in
                    switch result {
                    case .success:
                        destinationFileURLs.append(destinationPath)
                    case .failure(let _error):
                        error = _error
                    }
                    completion()
                }
            },
            completion: {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(destinationFileURLs))
                }
            })
    }

    func moveBatchOfFilesToLocalTemporary(files: [File], completion: @escaping (Result<[URL], Error>) -> Void) {
        let conflictResolve = NameConflictResolverError()
        var destinationFileURLs: [URL] = []
        var error: Error?

        DispatchGroup.perform(
            value: files,
            action: { [self] file, completion in
                let temporaryStorage = File.localUUIDTemporaryFolder()
                createFolder(at: temporaryStorage) { _ in
                }
                let destinationPath = temporaryStorage.makeSubfile(name: file.name, isDirectory: file.isFolder()).path
                move(file: file, destination: temporaryStorage, conflictResolver: conflictResolve) { result in
                    switch result {
                    case .success:
                        destinationFileURLs.append(destinationPath)
                    case .failure(let _error):
                        error = _error
                    }
                }
                completion()
            },
            completion: {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(destinationFileURLs))
                }
            })
    }

    func saveFilesFromLocalTemporary(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void) {
        move(
            files: files,
            destination: destination,
            conflictResolver: conflictResolver,
            completion: completion)
    }

    func getLocalFileURL(file: File, completion: @escaping (Result<URL, Error>) -> Void) {
        completion(.success(file.path))
    }
}


