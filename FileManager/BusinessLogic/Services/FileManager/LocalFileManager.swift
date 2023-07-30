//
//  LocalFileManager.swift
//  SystemFileManger
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import Foundation

final class LocalFileManager {
    enum Constants {
        static let root = "Root"
        static let trash = "Trash"
        static let downloads = "Downloads"
    }
    
    private let fileManagerRootPath: FileManagerRootPath
    private lazy var documentsURL = fileManagerRootPath.documentsURL
    private(set) lazy var rootFolder = makeDefaultFolder(name: Constants.root, destination: documentsURL)
    private(set) lazy var trashFolder = makeDefaultFolder(name: Constants.trash, destination: rootFolder.path)
    private(set) lazy var downloadsFolder = makeDefaultFolder(name: Constants.downloads, destination: rootFolder.path)
    
    init(fileManagerRootPath: FileManagerRootPath = LocalFileMangerRootPath()) {
        self.fileManagerRootPath = fileManagerRootPath
        _ = rootFolder
        _ = trashFolder
        _ = downloadsFolder
    }
}

extension LocalFileManager: FileManager {
    
    func contents(of file: File, completion: (Result<[File], Error>) -> Void) {
        do {
            var files: [File] = []
            for path in try SystemFileManger.default.contentsOfDirectory(at: file.path, includingPropertiesForKeys: nil) {
                var file = File(path: path)
                updateFileActions(file: &file)
                updateFolderAffiliation(file: &file)
                files.append(file)
            }
            completion(.success(files))
        } catch {
            completion(.failure(Error(error: error)))
        }
    }
    
    func createFolder(at file: File, completion: (Result<Void, Error>) -> Void) {
        do {
            try SystemFileManger.default.createDirectory(at: file.path, withIntermediateDirectories: false)
            completion(.success(()))
        } catch {
            completion(.failure(Error(error: error)))
        }
    }
    
    func copy(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void)
    {
        let destination = destination.makeSubfile(name: file.name)
        if SystemFileManger.default.fileExists(atPath: destination.path.path) {
            conflictResolve(fileToCopy: file, destination: destination, conflictResolver: conflictResolver) { conflictResolveResult in
                switch conflictResolveResult {
                case .success(let choice):
                    completion(.success(choice))
                case .failure(let error):
                    //not sure
                    completion(.failure(Error(error: error)))
                }
            }
        } else {
            do {
                try SystemFileManger.default.copyItem(at: file.path, to: destination.path)
                completion(.success(.finished))
            } catch {
                completion(.failure(Error(error: error)))
            }
        }
    }
    
    func copy(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void)
    {
        guard let file = files.first else {
            completion(.success(.finished))
            return
        }
        
        copy(file: file, destination: destination, conflictResolver: conflictResolver) { [weak self] result in
            switch result {
            case .success(let result):
                if result == .cancelled {
                    completion(.success(.cancelled))
                    return
                }
                let files = files.dropFirst()
                self?.copy(files: Array(files), destination: destination, conflictResolver: conflictResolver, completion: completion)
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
        
    }
    
    func move(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void)
    {
        guard let file = files.first else {
            completion(.success(.finished))
            return
        }
        
        move(file: file, destination: destination, conflictResolver: conflictResolver) { [weak self] result in
            switch result {
            case .success(let cancelChoice):
                if cancelChoice == .cancelled {
                    completion(.success(.cancelled))
                    return
                }
                let files = files.dropFirst()
                self?.move(files: Array(files), destination: destination, conflictResolver: conflictResolver, completion: completion)
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
    }
    
    func move(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void)
    {
        copy(file: file, destination: destination, conflictResolver: conflictResolver) { copyResult in
            switch copyResult {
            case .success(let cancelChoice):
                if cancelChoice == .cancelled {
                    completion(.success(.cancelled))
                    return
                }
                self.deleteFile(files: [file]) { result in
                    switch result {
                    case .success:
                        completion(.success(.finished))
                    case .failure(let error):
                        completion(.failure(Error(error: error)))
                    }
                }
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
    }

    func moveToTrash(filesToTrash: [File], completion: (Result<Void, Error>) -> Void) {
        for file in filesToTrash {
            var fileToTrashTemp = file
            var trashedFilePath: URL {
                trashFolder.path.appendingPathComponent(fileToTrashTemp.name)
            }
            do {
                if SystemFileManger.default.fileExists(atPath: trashedFilePath.path) {
                    fileToTrashTemp.addTimeToName()
                }
                try SystemFileManger.default.moveItem(at: file.path, to: trashedFilePath)
            } catch {
                completion(.failure(Error(error: error)))
            }
        }
        completion(.success(()))
    }
    
    func deleteFile(files: [File], completion: (Result<Void, Error>) -> Void) {
        for file in files {
            do {
                try SystemFileManger.default.removeItem(at: file.path)
            }
            catch {
                completion(.failure(Error(error: error)))
                return
            }
        }
        completion(.success(()))
    }
    
    func cleanTrashFolder(completion: (Result<Void, Error>) -> Void) {
        contents(of: trashFolder) { result in
            switch result {
            case .success(let files):
                deleteFile(files: files, completion: completion)
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
    }
    
    func rename(file: File, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let renamedFile = file.rename(name: newName)
        do {
            try SystemFileManger.default.moveItem(at: file.path, to: renamedFile.path)
            completion(.success(()))
        } catch {
            completion(.failure(Error(error: error)))
        }
    }
}

// MARK: - Private

private extension LocalFileManager {
    
    func makeDefaultFolder(name: String, destination: URL) -> File {
        var file = File(path: destination.appendingPathComponent(name))
        if SystemFileManger.default.fileExists(atPath: file.path.path) {
            return file
        }
        do {
            try SystemFileManger.default.createDirectory(at: file.path, withIntermediateDirectories: false)
        } catch {
            fatalError("Failed to create directory with error: \(error)")
        }
        updateFileActions(file: &file)
        updateFolderAffiliation(file: &file)
        return file
    }
    
    func updateFileActions(file: inout File) {
        if file == trashFolder {
            file.actions = FileAction.trashFolderActions
        } else if file == downloadsFolder {
            file.actions = FileAction.downloadsFolderActions
        } else {
            file.actions = FileAction.regularFolder
        }
    }
    
    func updateFolderAffiliation(file: inout File) {
        if file == trashFolder {
            file.folderAffiliation = .system
        } else if file == downloadsFolder {
            file.folderAffiliation = .system
        }
    }
    
    func copyFileWithNewName(file: File, destination: File) -> Result<Void, Error> {
        var destinationPath = destination
        var numberOfCopy = 1
        repeat {
            let newName = destination.name + R.string.localizable.copyInName.callAsFunction() + "\(numberOfCopy)"
            destinationPath = destinationPath.rename(name: newName)
            numberOfCopy += 1
        } while SystemFileManger.default.fileExists(atPath: destinationPath.path.path)
        
        do {
            try SystemFileManger.default.copyItem(at: file.path, to: destinationPath.path)
            return .success(())
        } catch {
            return .failure(Error(error: error))
        }
    }
    
    func replaceFile(fileToCopy: File, destination: File) -> Result<Void, Error> {
        let destinationPath = destination
        do {
            try SystemFileManger.default.removeItem(at: destination.path)
            try SystemFileManger.default.copyItem(at: fileToCopy.path, to: destinationPath.path)
            return .success(())
        } catch {
            return .failure(Error(error: error))
        }
    }
    
    func conflictResolve(fileToCopy: File, destination: File, conflictResolver: NameConflictResolver, completion: @escaping (Result<OperationResult, Error>) -> Void)  {
        conflictResolver.resolve { result in
            switch result {
            case .cancel:
                completion(.success(.cancelled))
            case .replace:
                switch self.replaceFile(fileToCopy: fileToCopy, destination: destination) {
                case .success:
                    completion(.success(.finished))
                case .failure(let error):
                    completion(.failure(Error(error: error)))
                }
            case .newName:
                switch self.copyFileWithNewName(file: fileToCopy, destination: destination) {
                case .success():
                    completion(.success(.finished))
                case .failure(let error):
                    completion(.failure(Error(error: error)))
                }
            }
        }
    }
}

