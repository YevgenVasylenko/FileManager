//
//  LocalFileManager+LocalTemporaryFolderConnector.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 18.01.2024.
//

import Foundation

extension LocalFileManager: LocalTemporaryFolderConnector {

    func copyBatchOfFilesToLocalTemporary(files: [File], completion: @escaping (Result<[URL], Error>) -> Void) {
        makeActionWithBatchOfFiles(files: files, action: copy, completion: completion)
    }

    func moveBatchOfFilesToLocalTemporary(files: [File], completion: @escaping (Result<[URL], Error>) -> Void) {
        makeActionWithBatchOfFiles(files: files, action: move, completion: completion)
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

private extension LocalFileManager {

    func makeActionWithBatchOfFiles(
        files: [File],
        action: @escaping (
            _ file: File,
            _ destination: File,
            NameConflictResolver,
            @escaping (Result<OperationResult, Error>) -> Void
        ) -> (),
        completion: @escaping (Result<[URL], Error>) -> Void
    ) {
        let conflictResolve = NameConflictResolverMock()
        var destinationFileURLs: [URL] = []
        var error: Error?

        DispatchGroup.perform(
            value: files,
            action: { file, completion in
                let temporaryStorage = File.localUUIDTemporaryFolder()
                _ = SystemFileManger.createFolder(at: temporaryStorage)
                let destinationPath = temporaryStorage.makeSubfile(name: file.name, isDirectory: file.isFolder()).path
                action(file, temporaryStorage, conflictResolve) { result in
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
}
