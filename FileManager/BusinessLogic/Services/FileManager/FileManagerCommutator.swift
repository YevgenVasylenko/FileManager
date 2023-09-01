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
        FileManagerFactory.makeFileManager(file: file).rename(file: file, newName: newName, completion: completion)
    }
    
    func copy(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        isForOneFile: Bool,
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
                isForOneFile: isForOneFile,
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
                let destinationFileManager = FileManagerFactory.makeFileManager(file: destination)
                destinationFileManager.saveFromLocalTemporary(
                    files: downloadedFiles,
                    destination: destination,
                    conflictResolver: conflictResolver,
                    isForOneFile: isForOneFile,
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
        isForOneFile: Bool,
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
                isForOneFile: isForOneFile,
                completion: completion
            )
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
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let firstFile = filesToRestore.first else {
            completion(.success(()))
            return
        }
        let fileManager = FileManagerFactory.makeFileManager(file: firstFile)
        fileManager.restoreFromTrash(filesToRestore: filesToRestore, completion: completion)
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
}
