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
        FileManagerFactory.makeFileManager(file: file).contents(of: file, completion: completion)
    }
    
    func contentBySearchingName(
        searchingPlace: SearchingPlace,
        file: File,
        name: String,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        var searchedFilesAcrossAll: [File] = []
        var error: Error?
        let fileManagers = makeListOfActiveFileManagers(file: file, searchingPlace: searchingPlace)

        DispatchGroup.perform(
            value: fileManagers,
            action: { fileManager, completion in
                fileManager.contentBySearchingName(
                    searchingPlace: searchingPlace,
                    file: file,
                    name: name
                ) { result in
                    switch result {
                    case .success(let files):
                        searchedFilesAcrossAll += files
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
                    completion(.success(searchedFilesAcrossAll))
                }
            })
    }

    func contentBySearchingNameAcrossTagged(
        tag: Tag,
        name: String,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        var foundedFilesAcrossAll: [File] = []
        var error: Error?
        let activeFileManagers = File.StorageType.activeStorages()

        DispatchGroup.perform(
            value: activeFileManagers,
            action: { fileManager, completion in
                fileManager.contentBySearchingNameAcrossTagged(
                    tag: tag,
                    name: name
                ) { result in
                    switch result {
                    case .success(let files):
                        foundedFilesAcrossAll += files
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
                    completion(.success(foundedFilesAcrossAll))
                }
            })
    }
    
    func createFolder(at file: File, completion: @escaping (Result<Void, Error>) -> Void) {
        FileManagerFactory.makeFileManager(file: file).createFolder(at: file, completion: completion)
    }
    
    func newNameForCreationOfFolder(
        at file: File,
        newFolderName: String,
        completion: @escaping (Result<File, Error>) -> Void
    ) {
        FileManagerFactory.makeFileManager(file: file).newNameForCreationOfFolder(
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
            .makeFileManager(file: file)
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
        let fileManager = FileManagerFactory.makeFileManager(file: firstFile)
        // For now application doesn't support multi storage type in files array
        if destination.storageType == firstFile.storageType {
            fileManager.copy(
                files: files,
                destination: destination,
                conflictResolver: conflictResolver,
                completion: completion
            )
            return
        }
        fileManager.copyBatchOfFilesToLocalTemporary(files: files) { result in
            switch result {
            case .failure(let error):
                completion(.failure(Error(error: error)))
            case .success(let sentFileURLs):
                var downloadedFiles: [File] = []
                for addressURL in sentFileURLs {
                    downloadedFiles.append(File(path: addressURL, storageType: destination.storageType))
                }
                let destinationFileManager = FileManagerFactory.makeFileManager(file: destination)
                destinationFileManager.saveFilesFromLocalTemporary(
                    files: downloadedFiles,
                    destination: destination,
                    conflictResolver: conflictResolver,
                    completion: completion
                )
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
        let fileManager = FileManagerFactory.makeFileManager(file: firstFile)
        // For now application doesn't support multi storage type in files array
        if destination.storageType == firstFile.storageType {
            fileManager.move(
                files: files,
                destination: destination,
                conflictResolver: conflictResolver,
                completion: completion
            )
            return
        }
        fileManager.moveBatchOfFilesToLocalTemporary(files: files) { result in
            switch result {
            case .failure(let error):
                completion(.failure(Error(error: error)))
            case .success(let sentFileURLs):
                var downloadedFiles: [File] = []
                for addressURL in sentFileURLs {
                    downloadedFiles.append(File(path: addressURL, storageType: destination.storageType))
                }
                let destinationFileManager = FileManagerFactory.makeFileManager(file: destination)
                destinationFileManager.saveFilesFromLocalTemporary(
                    files: downloadedFiles,
                    destination: destination,
                    conflictResolver: conflictResolver,
                    completion: completion
                )
            }
        }
    }

    func moveToTrash(filesToTrash: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let firstFile = filesToTrash.first else {
            completion(.success(()))
            return
        }
        let fileManager = FileManagerFactory.makeFileManager(file: firstFile)
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
        let fileManager = FileManagerFactory.makeFileManager(file: firstFile)
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
        let fileManager = FileManagerFactory.makeFileManager(file: firstFile)
        fileManager.deleteFile(files: files, completion: completion)
    }
    
    func cleanTrashFolder(
        fileForFileManager: File,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let fileManager = FileManagerFactory.makeFileManager(file: fileForFileManager)
        fileManager.cleanTrashFolder(fileForFileManager: fileForFileManager, completion: completion)
    }
    
    func makeFolderMonitor(file: File) -> FolderMonitor? {
        let fileManager = FileManagerFactory.makeFileManager(file: file)
        return fileManager.makeFolderMonitor(file: file)
    }
    
    func getLocalFileURL(file: File, completion: @escaping (Result<URL, Error>) -> Void) {
        let fileManager = FileManagerFactory.makeFileManager(file: file)
        fileManager.getLocalFileURL(file: file, completion: completion)
    }
    
    func getFileAttributes(file: File, completion: @escaping (Result<FileAttributes, Error>) -> Void) {
        let fileManager = FileManagerFactory.makeFileManager(file: file)
        fileManager.getFileAttributes(file: file, completion: completion)
    }

    func addTags(to file: File, tags: [Tag], completion: @escaping (Result<Void, Error>) -> Void) {
        let fileManager = FileManagerFactory.makeFileManager(file: file)
        fileManager.addTags(to: file, tags: tags, completion: completion)
    }

    func getActiveTagIds(on file: File, completion: @escaping (Result<[String], Error>) -> Void) {
        let fileManager = FileManagerFactory.makeFileManager(file: file)
        fileManager.getActiveTagIds(on: file, completion: completion)
    }

    func filesWithTag(tag: Tag, completion: @escaping (Result<[File], Error>) -> Void) {
        var allFilesAcrossStoragesWithTag: [File] = []
        var error: Error?
        let activeFileManagers = File.StorageType.activeStorages()

        DispatchGroup.perform(
            value: activeFileManagers,
            action: { fileManager, completion in
                fileManager.filesWithTag(tag: tag) { result in
                    switch result {
                    case .success(let files):
                        allFilesAcrossStoragesWithTag += files
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
                    completion(.success(allFilesAcrossStoragesWithTag))
                }
            })
    }

    func canPerformAction(
        fileAction: FileActionType,
        sourceStorage: File.StorageType,
        destinationStorage: File.StorageType
    ) -> Bool {
        let fileManager = FileManagerFactory.makeFileManager(storage: sourceStorage)

        return fileManager.canPerformAction(
            fileAction: fileAction,
            sourceStorage: sourceStorage,
            destinationStorage: destinationStorage
        )
    }
}

// MARK: - Private

private extension FileManagerCommutator {
    func makeListOfActiveFileManagers(file: File, searchingPlace: SearchingPlace) -> [FileManager] {
        switch searchingPlace {
        case .currentStorage, .currentFolder, .currentTrash:
            return [FileManagerFactory.makeFileManager(file: file)]
        case .allStorages:
            return File.StorageType.activeStorages()
        }
    }
}
