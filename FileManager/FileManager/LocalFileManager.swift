//
//  LocalFileManager.swift
//  SystemFileManger
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import Foundation

// make protocol in new file describe functions

final class LocalFileManager {
    enum Constants {
        static let root = "root"
        static let trash = "root/trash"
        static let downloads = "root/downloads"
    }
    
//    enum Error: Error {
//        case underLyingerror
//    }

    private let fileManagerRootPath: FileManagerRootPath
    private lazy var documentsURL = fileManagerRootPath.documentsURL
    private(set) lazy var rootFolder = makeDefaultFolder(name: Constants.root)
    private(set) lazy var trashFolder = makeDefaultFolder(name: Constants.trash)
    private(set) lazy var downloadsFolder = makeDefaultFolder(name: Constants.downloads)
    
    init(fileManagerRootPath: FileManagerRootPath = LocalFileMangerRootPath()) {
        self.fileManagerRootPath = fileManagerRootPath
    }
}

extension LocalFileManager: FileManager {

    func contents(of file: File, completion: (Result<[File], Error>) -> Void) {
        do {
            var files: [File] = []
            for path in try SystemFileManger.default.contentsOfDirectory(at: file.path, includingPropertiesForKeys: nil, options: .producesRelativePathURLs) {
                files.append(File(path: path))
            }
            completion(.success(files))
        } catch {
            completion(.failure(error))
        }
    }
    
    func createFolder(at file: File, completion: (Result<Void, Error>) -> Void) {
        do {
            try SystemFileManger.default.createDirectory(at: file.path, withIntermediateDirectories: false)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func copyFile(
        fileToCopy: File,
        destination: File,
        conflictResolver: ConflictResolver,
        completion: (Result<OperationResult, Error>) -> Void)
    {
        if SystemFileManger.default.fileExists(atPath: destination.path.path) {
            conflictResolve(fileToCopy: fileToCopy, destination: destination, conflictResolver: conflictResolver) { conflictResolveResult in
                switch conflictResolveResult {
                case .success(let choice):
                    completion(.success(choice))
                case .failure(let error):
                     completion(.failure(error))
                }
            }
        } else {
            do {
                try SystemFileManger.default.copyItem(at: fileToCopy.path, to: destination.path)
                completion(.success(.finished))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func moveFile(fileToCopy: File, destination: File, conflictResolver: ConflictResolver, completion: (Result<Void, Error>) -> Void) {
        copyFile(fileToCopy: fileToCopy, destination: destination, conflictResolver: conflictResolver) { copyResult in
            switch copyResult {
            case .success(let cancelChoice):
                if cancelChoice == .cancelled {
                    completion(.success(()))
                    return
                }
                deleteFile(file: fileToCopy, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func moveToTrash(fileToTrash: File, completion: (Result<File, Error>) -> Void) {
        var fileToTrashTemp = fileToTrash
        var trashedFilePath: URL {
            trashFolder.path.appendingPathComponent(fileToTrashTemp.name)
        }
        do {
            if SystemFileManger.default.fileExists(atPath: trashedFilePath.path) {
                fileToTrashTemp.addTimeToName()
            }
            try SystemFileManger.default.moveItem(at: fileToTrash.path, to: trashedFilePath)
            completion(.success(fileToTrashTemp))
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteFile(file: File, completion: (Result<Void, Error>) -> Void) {
        do {
            try SystemFileManger.default.removeItem(at: file.path)
            completion(.success(()))
        }
        catch {
            completion(.failure(error))
        }
    }
}

// MARK: - Private

private extension LocalFileManager {

    func makeDefaultFolder(name: String) -> File {
        let file = File(path: documentsURL.appendingPathComponent(name))
        if SystemFileManger.default.fileExists(atPath: file.path.path) {
            return file
        }
        do {
            try SystemFileManger.default.createDirectory(at: file.path, withIntermediateDirectories: false)
        } catch {
            fatalError("Failed to create directory with error: \(error)")
        }
        return file
    }
    
    func copyFileWithNewName(file: File, destination: File) -> Result<Void, Error> {
        var destinationPath = destination
        var numberOfCopy = 1
        repeat {
            let newName = destinationPath.name + (" Copy_\(numberOfCopy)")
            destinationPath.rename(name: newName)
            numberOfCopy += 1
        } while SystemFileManger.default.fileExists(atPath: destinationPath.path.path)
        
        do {
            try SystemFileManger.default.copyItem(at: file.path, to: destinationPath.path)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func replaceFile(fileToCopy: File, destination: File) -> Result<Void, Error> {
        let destinationPath = destination
        do {
            try SystemFileManger.default.removeItem(at: destination.path)
            try SystemFileManger.default.copyItem(at: fileToCopy.path, to: destinationPath.path)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func conflictResolve(fileToCopy: File, destination: File, conflictResolver: ConflictResolver, completion: (Result<OperationResult, Error>) -> Void)  {
        switch conflictResolver.resolve() {
        case .cancel:
            completion(.success(.cancelled))
            
        case .replace:
            switch replaceFile(fileToCopy: fileToCopy, destination: destination) {
            case .success:
                completion(.success(.finished))
            case .failure(let error):
                completion(.failure(error))
            }
            
        case .newName:
            switch copyFileWithNewName(file: fileToCopy, destination: destination) {
            case .success():
                completion(.success(.finished))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}

