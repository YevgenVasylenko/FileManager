//
//  LocalFileManager.swift
//  SystemFileManger
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import Foundation

final class LocalFileManager {
    enum Constants {
        static let root = "root"
        static let trash = "trash"
        static let downloads = "downloads"
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
                var newFile = File(path: path, storageType: .local(LocalStorageData()))
                if file.isDeleted {
                    newFile.isDeleted = true
                }
                updateFileActionsAndDeleteStatus(file: &newFile)
                updateFolderAffiliation(file: &newFile)
                files.append(newFile)
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
    
    func newNameForCreationOfFolder(
        at file: File,
        newFolderName: String,
        completion: @escaping (Result<File, Error>) -> Void
    ) {
        let destinationFile = file.makeSubfile(name: newFolderName, isDirectory: true)
        var fileForChanges = destinationFile
        var numberOfFolder = 0
        repeat {
            let suffixToName = numberOfFolder == 0 ? "" : " \(numberOfFolder)"
            let newName = destinationFile.name + suffixToName
            fileForChanges = fileForChanges.rename(name: newName)
            numberOfFolder += 1
        } while SystemFileManger.default.fileExists(atPath: fileForChanges.path.path)
        completion(.success(fileForChanges))
    }
    
    func copy(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
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
                self?.copy(
                    files: Array(files),
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
                self?.move(
                    files: Array(files),
                    destination: destination,
                    conflictResolver: conflictResolver,
                    completion: completion
                )
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
                Database.Tables.FilesInTrash.insertRowToFilesInTrashDB(fileToTrash: file, fileInTrashPath: trashedFilePath)
            } catch {
                completion(.failure(Error(error: error)))
                return
            }
        }
        completion(.success(()))
    }
    
    func restoreFromTrash(
        filesToRestore: [File],
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        for file in filesToRestore {
            guard let pathToRestore = Database.Tables.FilesInTrash.getPathForRestore(file: file) else {
                completion(.failure(Error.unknown))
                return
            }
            let restoredFile = File(path: pathToRestore, storageType: .local(LocalStorageData()))
            let parentFolderOfRestoredFile = restoredFile.parentFolder()
            if isParentFolderExist(parentFolder: parentFolderOfRestoredFile) {
                moveFromTrashIfParentFolderExist(
                    file: file,
                    parentDestination: parentFolderOfRestoredFile,
                    conflictResolver: conflictResolver,
                    completion: completion
                )
            } else {
                moveFromTrashIfParentFolderNotExist(
                    file: file,
                    parentDestination: parentFolderOfRestoredFile,
                    conflictResolver: conflictResolver,
                    completion: completion
                )
            }
        }
    }
    
    func deleteFile(files: [File], completion: (Result<Void, Error>) -> Void) {
        for file in files {
            do {
                try SystemFileManger.default.removeItem(at: file.path)
                Database.Tables.FilesInTrash.deleteFromDB(file: file)
            }
            catch {
                completion(.failure(Error(error: error)))
                return
            }
        }
        completion(.success(()))
    }
    
    func cleanTrashFolder(fileForFileManager: File, completion: (Result<Void, Error>) -> Void) {
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
    
    func makeFolderMonitor(file: File) -> FolderMonitor? {
        return LocalFolderMonitor(url: file.path)
    }
    
    func getFileAttributes(file: File, completion: @escaping (Result<FileAttributes, Error>) -> Void) {
        do {
            let attributes = try SystemFileManger.default.attributesOfItem(atPath: file.path.path)
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            let modifiedDate = attributes[.modificationDate] as? Date ?? Date()
            var size = Double()
            if file.isFolder() {
                if let enumerator = SystemFileManger.default.enumerator(at: file.path, includingPropertiesForKeys: [.fileSizeKey]) {
                    for case let filePath as URL in enumerator {
                            do {
                                let fileAttributes = try filePath.resourceValues(forKeys: [.fileSizeKey])
                                size += Double(fileAttributes.fileSize ?? Int())
                            } catch {
                                completion(.failure(Error(error: error)))
                                return
                            }
                        }
                    }
            } else {
                size = attributes[.size] as? Double ?? Double()
            }
            completion(.success(FileAttributes(size: size, createdDate: creationDate, modifiedDate: modifiedDate)))
        } catch {
            completion(.failure(Error(error: error)))
        }
    }
}

extension LocalFileManager: LocalTemporaryFolderConnector {
    
    func copyToLocalTemporary(files: [File], completion: @escaping (Result<[URL], Error>) -> Void) {
        let conflictResolve = NameConflictResolverError()
        let group = DispatchGroup()
        var destinationFileURLs: [URL] = []
        for file in files {
            group.enter()
            let temporaryStorage = File(
                path: SystemFileManger.default.temporaryDirectory.appendingPathComponent(
                    UUID().uuidString, isDirectory: true),
                storageType: .local(LocalStorageData())
            )
            createFolder(at: temporaryStorage) { _ in
            }
            let destinationPath = temporaryStorage.makeSubfile(name: file.name).path
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
    
    func saveFromLocalTemporary(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void) {
        move(
            files: files,
            destination: destination,
            conflictResolver: conflictResolver
        ) { result in
        }
    }
    
    func getLocalFileURL(file: File, completion: @escaping (Result<URL, Error>) -> Void) {
        completion(.success(file.path))
    }
}

// MARK: - Private

private extension LocalFileManager {
    
    func makeDefaultFolder(name: String, destination: URL) -> File {
        var file = File(path: destination.appendingPathComponent(name), storageType: .local(LocalStorageData()))
        if SystemFileManger.default.fileExists(atPath: file.path.path) {
            return file
        }
        do {
            try SystemFileManger.default.createDirectory(at: file.path, withIntermediateDirectories: false)
        } catch {
            fatalError("Failed to create directory with error: \(error)")
        }
        updateFileActionsAndDeleteStatus(file: &file)
        updateFolderAffiliation(file: &file)
        return file
    }
    
    func updateFileActionsAndDeleteStatus(file: inout File) {
        if file == trashFolder {
            file.actions = FileAction.trashFolderActions
        } else if file == downloadsFolder {
            file.actions = FileAction.downloadsFolderActions
        } else if file == trashFolder.makeSubfile(name: file.name) ||
                    file == trashFolder.makeSubfile(name: file.name, isDirectory: true) || file.isDeleted {
            file.actions = [FileAction.delete, FileAction.restoreFromTrash]
            file.isDeleted = true
        } else {
            file.actions = FileAction.regularFolder
        }
    }
    
    func updateFolderAffiliation(file: inout File) {
        if file == trashFolder {
            file.folderAffiliation = .system(.trash)
        } else if file == downloadsFolder {
            file.folderAffiliation = .system(.download)
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

    func copyFileWithNewName(file: File, destination: File) -> Result<Void, Error> {
        var finalFile = destination
        var numberOfCopy = 1
        repeat {
            let newName = destination.nameWithoutExtension + " (\(numberOfCopy))"
            finalFile = finalFile.rename(name: newName)
            numberOfCopy += 1
        } while SystemFileManger.default.fileExists(atPath: finalFile.path.path)
        
        do {
            try SystemFileManger.default.copyItem(at: file.path, to: finalFile.path)
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
        let placeOfConflict = File(path: destination.path.deletingLastPathComponent(), storageType: .local(LocalStorageData()))
        conflictResolver.resolve(conflictedFile: fileToCopy, placeOfConflict: placeOfConflict) { result in
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
            case .error:
                completion(.failure(Error(error: Error.unknown)))
            }
        }
    }

    func isParentFolderExist(parentFolder: File) -> Bool {
        SystemFileManger.default.fileExists(atPath: parentFolder.path.path)
    }
    
    func moveFromTrashIfParentFolderExist(
        file: File,
        parentDestination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        move(
            file: file,
            destination: parentDestination,
            conflictResolver: conflictResolver,
            completion: { result in
                switch result {
                case .success(let choice):
                    switch choice {
                    case .finished:
                        Database.Tables.FilesInTrash.deleteFromDB(file: file)
                        completion(.success((.finished)))
                    case .cancelled:
                        completion(.success(.cancelled))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            })
    }
    
    func moveFromTrashIfParentFolderNotExist(
        file: File,
        parentDestination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        do {
            try SystemFileManger.default.createDirectory(at: parentDestination.path, withIntermediateDirectories: true)
            move(
                file: file,
                destination: parentDestination,
                conflictResolver: conflictResolver,
                completion: completion
            )
        } catch {
            completion(.failure(Error(error: error)))
        }
    }
}

struct NameConflictResolverError: NameConflictResolver {
    var mockResult: ConflictNameResult = .error

    func resolve(conflictedFile: File, placeOfConflict: File, completion: @escaping (ConflictNameResult) -> Void) {
        completion(mockResult)
    }
}
