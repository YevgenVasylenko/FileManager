//
//  FileManagerCommutator.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 06.08.2023.
//

import Foundation

final class FileManagerCommutator {
}

extension FileManagerCommutator: FileManager {

   func contents(of file: File, completion: @escaping (Result<[File], Error>) -> Void) {
       FileManagerFactory.makeFileManager(storage: file.storageType).contents(of: file, completion: completion)
    }
    
    func contentBySearchingName(
        searchingPlace: SearchingPlace,
        file: File,
        name: String,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        var searchedFilesAcrossAll: [File] = []
        let group = DispatchGroup()
        var error: Error?
        for storage in makeListOfActiveFileManagers(file: file, searchingPlace: searchingPlace) {
            group.enter()
            storage.contentBySearchingName(
                searchingPlace: searchingPlace,
                file: file,
                name: name) { result in
                    defer { group.leave() }
                    switch result {
                    case .success(let files):
                        searchedFilesAcrossAll += files
                    case .failure(let _error):
                        error = _error
                    }
                }
        }
        group.notify(queue: .main) {
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(searchedFilesAcrossAll))
            }
        }
    }
    
    func createFolder(at file: File, completion: @escaping (Result<Void, Error>) -> Void) {
        FileManagerFactory.makeFileManager(storage: file.storageType).createFolder(at: file, completion: completion)
    }
    
    func newNameForCreationOfFolder(
        at file: File,
        newFolderName: String,
        completion: @escaping (Result<File, Error>) -> Void
    ) {
        FileManagerFactory.makeFileManager(storage: file.storageType).newNameForCreationOfFolder(
            at: file,
            newFolderName: newFolderName,
            completion: completion
        )
    }
    
    func rename(
        file: File,
        newName: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        FileManagerFactory
            .makeFileManager(storage: file.storageType)
            .rename(file: file, newName: newName, completion: completion)
    }
    
    func copy(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let firstFile = files.first else {
            completion(.success(.finished))
            return
        }
        let fileManager = FileManagerFactory.makeFileManager(storage: firstFile.storageType)
        // For now application doesn't support multi storage type in files array
        if destination.storageType == firstFile.storageType {
            fileManager.copy(
                files: files,
                destination: destination,
                conflictResolver: conflictResolver,
                completion: completion)
            return
        }
        fileManager.copyToLocalTemporary(files: files) { result in
            switch result {
            case .success(let sentFileURLs):
                var downloadedFiles: [File] = []
                for addressURL in sentFileURLs {
                    downloadedFiles.append(File(path: addressURL, storageType: destination.storageType))
                }
                let destinationFileManager = FileManagerFactory.makeFileManager(storage: destination.storageType)
                destinationFileManager.saveFromLocalTemporary(
                    files: downloadedFiles,
                    destination: destination,
                    conflictResolver: conflictResolver,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
    }

    func move(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let firstFile = files.first else {
            completion(.success(.finished))
            return
        }
        let fileManager = FileManagerFactory.makeFileManager(storage: firstFile.storageType)
        // For now application doesn't support multi storage type in files array
        if destination.storageType == firstFile.storageType {
            fileManager.move(
                files: files,
                destination: destination,
                conflictResolver: conflictResolver,
                completion: completion
            )
        }
    }

    func moveToTrash(filesToTrash: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let firstFile = filesToTrash.first else {
            completion(.success(()))
            return
        }
        let fileManager = FileManagerFactory.makeFileManager(storage: firstFile.storageType)
        fileManager.moveToTrash(filesToTrash: filesToTrash, completion: completion)
    }
    
    func restoreFromTrash(
        filesToRestore: [File],
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let firstFile = filesToRestore.first else {
            completion(.success((.cancelled)))
            return
        }
        let fileManager = FileManagerFactory.makeFileManager(storage: firstFile.storageType)
        fileManager.restoreFromTrash(
            filesToRestore: filesToRestore,
            conflictResolver: conflictResolver,
            completion: completion)
    }
    
    func deleteFile(files: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let firstFile = files.first else {
            completion(.success(()))
            return
        }
        let fileManager = FileManagerFactory.makeFileManager(storage: firstFile.storageType)
        fileManager.deleteFile(files: files, completion: completion)
    }
    
    func cleanTrashFolder(
        fileForFileManager: File,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let fileManager = FileManagerFactory.makeFileManager(storage: fileForFileManager.storageType)
        fileManager.cleanTrashFolder(fileForFileManager: fileForFileManager, completion: completion)
    }
    
    func makeFolderMonitor(file: File) -> FolderMonitor? {
        let fileManager = FileManagerFactory.makeFileManager(storage: file.storageType)
        return fileManager.makeFolderMonitor(file: file)
    }
    
    func getLocalFileURL(file: File, completion: @escaping (Result<URL, Error>) -> Void) {
        let fileManager = FileManagerFactory.makeFileManager(storage: file.storageType)
        fileManager.getLocalFileURL(file: file, completion: completion)
    }
    
    func getFileAttributes(file: File, completion: @escaping (Result<FileAttributes, Error>) -> Void) {
        let fileManager = FileManagerFactory.makeFileManager(storage: file.storageType)
        fileManager.getFileAttributes(file: file, completion: completion)
    }

    func addTags(to file: File, tags: [Tag], completion: @escaping (Result<Void, Error>) -> Void) {
        let fileManager = FileManagerFactory.makeFileManager(storage: file.storageType)
        fileManager.addTags(to: file, tags: tags, completion: completion)
    }

    func getActiveTagIds(on file: File, completion: @escaping (Result<[String], Error>) -> Void) {
        let fileManager = FileManagerFactory.makeFileManager(storage: file.storageType)
        fileManager.getActiveTagIds(on: file, completion: completion)
    }

    func filesWithTag(tag: Tag, completion: @escaping (Result<[File], Error>) -> Void) {
        var allFilesAcrossStoragesWithTag: [File] = []
        let group = DispatchGroup()
        var error: Error?
        for storage in File.StorageType.activeStorages() {
            group.enter()
            storage.filesWithTag(tag: tag) { result in
                defer { group.leave() }
                switch result {
                case .success(let files):
                    allFilesAcrossStoragesWithTag += files
                case .failure(let _error):
                    error = _error
                }
            }
        }
        group.notify(queue: .main) {
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(allFilesAcrossStoragesWithTag))
            }
        }
    }
}

// MARK: - Private

private extension FileManagerCommutator {
    func makeListOfActiveFileManagers(file: File, searchingPlace: SearchingPlace) -> [FileManager] {
        switch searchingPlace {
        case .currentStorage, .currentFolder, .currentTrash:
            return [FileManagerFactory.makeFileManager(storage: file.storageType)]
        case .allStorages:
            return File.StorageType.activeStorages()
        }
    }
}
