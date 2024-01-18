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
        let group = DispatchGroup()
        var destinationFileURLs: [URL] = []
        for file in files {
            group.enter()
            let temporaryStorage = File(
                path: SystemFileManger.default.temporaryDirectory.appendingPathComponent(
                    UUID().uuidString, isDirectory: true),
                storageType: .local
            )
            createFolder(at: temporaryStorage) { _ in
            }
            let destinationPath = temporaryStorage.makeSubfile(name: file.name, isDirectory: file.isFolder()).path
            copy(file: file, destination: temporaryStorage, conflictResolver: conflictResolve) { result in
                switch result {
                case .success:
                    defer { group.leave() }
                    destinationFileURLs.append(destinationPath)
                case .failure(let error):
                    defer { group.leave() }
                    completion(.failure(Error(error: error)))
                    return
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion(.success(destinationFileURLs))
        }
    }

    func moveBatchOfFilesToLocalTemporary(files: [File], completion: @escaping (Result<[URL], Error>) -> Void) {
        let conflictResolve = NameConflictResolverError()
        let group = DispatchGroup()
        var destinationFileURLs: [URL] = []
        for file in files {
            group.enter()
            let temporaryStorage = File(
                path: SystemFileManger.default.temporaryDirectory.appendingPathComponent(
                    UUID().uuidString, isDirectory: true),
                storageType: .local
            )
            createFolder(at: temporaryStorage) { _ in
            }
            let destinationPath = temporaryStorage.makeSubfile(name: file.name).path
            move(file: file, destination: temporaryStorage, conflictResolver: conflictResolve) { result in
                switch result {
                case .success:
                    defer { group.leave() }
                    destinationFileURLs.append(destinationPath)
                case .failure(let error):
                    defer { group.leave() }
                    completion(.failure(Error(error: error)))
                    return
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion(.success(destinationFileURLs))
        }
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


