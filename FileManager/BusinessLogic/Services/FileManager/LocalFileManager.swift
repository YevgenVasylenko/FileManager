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
        static let tagAttributeName = "Tags"
    }

    private(set) var rootFolder: File
    private(set) var trashFolder: File
    private(set) var downloadsFolder: File

    init(fileManagerRootPath: FileManagerRootPath = LocalFileMangerRootPath()) {
        rootFolder = Self.makeDefaultFolder(
            name: Constants.root,
            destination: fileManagerRootPath.documentsURL
        )
        trashFolder = Self.makeDefaultFolder(
            name: Constants.trash,
            destination: rootFolder.path
        )
        downloadsFolder = Self.makeDefaultFolder(
            name: Constants.downloads,
            destination: rootFolder.path
        )

        rootFolder = updatedFile(file: rootFolder)
        trashFolder = updatedFile(file: trashFolder)
        downloadsFolder = updatedFile(file: downloadsFolder)
    }
}

extension LocalFileManager: FileManager {

    func contents(of file: File, completion: (Result<[File], Error>) -> Void) {
        do {
            var files: [File] = []
            for path in try SystemFileManger.default.contentsOfDirectory(
                at: file.path,
                includingPropertiesForKeys: nil
            ) {
                var newFile = File(path: path, storageType: .local)
                newFile = updatedFile(file: newFile)
                files.append(newFile)
            }
            completion(.success(files))
        } catch {
            completion(.failure(Error(error: error)))
        }
    }
    
    func contentBySearchingName(
        searchingPlace: SearchingPlace,
        file: File,
        name: String,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        let enumerator = enumeratorDependOnSearchingPlace(searchingPlace: searchingPlace, currentFolder: file)
        let allFiles = SystemFileManger.allFilesIn(enumerator: enumerator)
        let filteredFiles = allFiles.filter { file in
            file.displayedName().lowercased().contains(name.lowercased())
        }
        completion(.success(filteredFiles))
    }

    func contentBySearchingNameAcrossTagged(
        tag: Tag,
        name: String,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        filesWithTag(tag: tag) { result in
            switch result {
            case .success(let files):
                let foundedFiles = files.filter { file in
                    file.displayedName().lowercased().contains(name.lowercased())
                }
                completion(.success(foundedFiles))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }

    func filesWithTag(tag: Tag, completion: @escaping (Result<[File], Error>) -> Void) {
        let enumerator = SystemFileManger.enumeratorFor(file: rootFolder)
        let allFilesInFolder = SystemFileManger.allFilesIn(enumerator: enumerator)
        let filteredFiles = allFilesInFolder.filter { file in
            getActiveTagNamesOnFile(file: file).contains(tag.id.uuidString)
        }
        completion(.success(filteredFiles))
    }
    
    func createFolder(at file: File, completion: (Result<Void, Error>) -> Void) {
        completion(
            SystemFileManger.createFolder(at: file)
        )
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
            case .failure(let error):
                completion(.failure(Error(error: error)))
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
            case .failure(let error):
                completion(.failure(Error(error: error)))
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
                    completion: completion)
            }
        }
    }
    
    func moveToTrash(filesToTrash: [File], completion: (Result<Void, Error>) -> Void) {
        for file in filesToTrash {
            var fileToTrashTemp = file
            var trashedFilePath: URL {
                trashFolder.path.appendingPathComponent(fileToTrashTemp.name)
            }
            while true {
                do {
                    if SystemFileManger.default.fileExists(atPath: trashedFilePath.path) {
                        fileToTrashTemp.addTimeToName()
                        continue
                    }
                    try SystemFileManger.default.moveItem(at: file.path, to: trashedFilePath)
                    Database.Tables.FilesInTrash.insertRowToFilesInTrashDB(fileToTrash: file, fileInTrashPath: trashedFilePath)
                    completion(.success(()))
                    break
                } catch {
                    let error = error as NSError
                    switch error.code {
                    case NSFileWriteFileExistsError:
                        fileToTrashTemp.addTimeToName()
                    default:
                        completion(.failure(Error(error: error)))
                        return
                    }
                }
            }
        }
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
            let restoredFile = File(path: pathToRestore, storageType: .local)
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

    func addTags(to file: File, tags: [Tag], completion: @escaping (Result<Void, Error>) -> Void) {
        addTagsToFile(file: file, tags: tags)
        completion(.success(()))
    }

    func getActiveTagIds(on file: File, completion: @escaping (Result<[String], Error>) -> Void) {
        completion(.success(getActiveTagNamesOnFile(file: file)))
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
                let error = error as NSError
                switch error.code {
                case NSFileWriteFileExistsError:
                    conflictResolve(fileToCopy: file, destination: destination, conflictResolver: conflictResolver) { conflictResolveResult in
                        switch conflictResolveResult {
                        case .success(let choice):
                            completion(.success(choice))
                        case .failure(let error):
                            completion(.failure(Error(error: error)))
                        }
                    }
                default:
                    completion(.failure(Error(error: error)))
                }
            }
        }
    }

    func move(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
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

    func canPerformAction(
        selectedDelegate: FileSelectDelegate,
        destinationStorage: File.StorageType
    ) -> Bool {
        switch selectedDelegate.type {
        case .copy:
            switch destinationStorage {
            case .local:
                return true
            case .dropbox:
                return true
            }
        case .move:
            switch destinationStorage {
            case .local:
                return true
            case .dropbox:
                return true
            }
        }
    }
}

// MARK: - Private

private extension LocalFileManager {
    
    static func makeDefaultFolder(name: String, destination: URL) -> File {
        let file = File(path: destination.appendingPathComponent(name), storageType: .local)
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
    
    func updatedFile(file: File) -> File {
        var file = file
        updateFileActionsAndDeleteStatus(file: &file)
        updateFolderAffiliation(file: &file)
        return file
    }
    
    func updateFileActionsAndDeleteStatus(file: inout File) {
        if file == trashFolder {
            file.actions = FileAction.trashFolder
        } else if file == downloadsFolder {
            file.actions = FileAction.downloadsFolder
        } else if file.hasParent(file: trashFolder) {
            file.actions = [FileAction.delete, FileAction.restoreFromTrash]
        } else {
            file.actions = FileAction.regularFile
        }
    }
    
    func updateFolderAffiliation(file: inout File) {
        if file == rootFolder {
            file.folderAffiliation = .system(.root)
        } else if file == trashFolder {
            file.folderAffiliation = .system(.trash)
        } else if file == downloadsFolder {
            file.folderAffiliation = .system(.download)
        } else {
            file.folderAffiliation = .user
        }
    }
    
    func copyFileWithNewName(file: File, destination: File) -> Result<Void, Error> {
        var finalFile = destination
        var numberOfCopy = 1
        while true {
            do {
                try SystemFileManger.default.copyItem(at: file.path, to: finalFile.path)
                return .success(())
            } catch {
                let error = error as NSError
                switch error.code {
                case NSFileWriteFileExistsError:
                    let newName = destination.nameWithoutExtension + " (\(numberOfCopy))"
                    finalFile = finalFile.rename(name: newName)
                    numberOfCopy += 1
                default:
                    return .failure(Error(error: error))
                }
            }
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
        let placeOfConflict = File(path: destination.path.deletingLastPathComponent(), storageType: .local)
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
    
    func enumeratorDependOnSearchingPlace(
        searchingPlace: SearchingPlace,
        currentFolder: File
    ) -> SystemFileManger.DirectoryEnumerator? {
        
        switch searchingPlace {
        case .currentStorage:
            return SystemFileManger.enumeratorFor(file: rootFolder)
        case .currentFolder:
            return SystemFileManger.enumeratorFor(file: currentFolder)
        case .currentTrash:
            return SystemFileManger.enumeratorFor(file: trashFolder)
        case .allStorages:
            return SystemFileManger.enumeratorFor(file: rootFolder)
        }
    }

    func getActiveTagNamesOnFile(file: File) -> [String] {
        let encodedTagIds = file.path.extendedAttribute(forName: Constants.tagAttributeName)
        return AttributesCoding.fromDataToArray(data: encodedTagIds)
    }

    func addTagsToFile(file: File, tags: [Tag]) {
        let tagIds = tags.map { $0.id.uuidString }
        let encodedTagIds = AttributesCoding.fromArrayToData(array: tagIds)
        file.path.setExtendedAttribute(data: encodedTagIds, forName: Constants.tagAttributeName)
    }
}

struct NameConflictResolverError: NameConflictResolver {
    var mockResult: ConflictNameResult = .error

    func resolve(conflictedFile: File, placeOfConflict: File, completion: @escaping (ConflictNameResult) -> Void) {
        completion(mockResult)
    }
}
