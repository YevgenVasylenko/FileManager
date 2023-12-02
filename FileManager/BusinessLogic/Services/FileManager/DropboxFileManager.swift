//
//  DropboxFileManager.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 31.07.2023.
//

import Foundation
import SwiftyDropbox

final class DropboxFileManager {
    enum Constants {
        static let root = ""
        static let trash = "trash"
    }
    
    private(set) var rootFolder: File
    private(set) var trashFolder: File
    
    init () {
        rootFolder = File(
            path: URL(fileURLWithPath: Constants.root),
            storageType: .dropbox
        )
        
        trashFolder = File(
            path: URL(fileURLWithPath: "/\(Constants.trash)"),
            storageType: .dropbox
        )
        
        rootFolder = updatedFile(file: rootFolder)
        trashFolder = updatedFile(file: trashFolder)
    }
}

extension DropboxFileManager: FileManager {
    
    func contents(of file: File, completion: @escaping (Result<[File], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = dropboxPath(file: file)
        
        if file.isDeleted || path == self.trashFolder.path.path {
            contentOfTrashFolder(file: file, completion: completion)
            return
        }
        client.files.listFolder(path: path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            var files: [File] = []
            self.addTrashFolderToRoot(file: file, files: &files)
            
            if let result = response {
                for fileInResult in result.entries {
                    var fileInFolder = File(
                        path: URL(fileURLWithPath: fileInResult.pathDisplay!),
                        storageType: .dropbox
                    )
                    self.correctFolderPath(file: &fileInFolder)
                    fileInFolder = self.updatedFile(file: fileInFolder)
                    files.append(fileInFolder)
                }
            }
            completion(.success(files))
        }
    }
   
    func contentBySearchingName(
        searchingPlace: SearchingPlace,
        file: File,
        name: String,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        getFilesDependOnSearchPlace(file: file, searchingPlace: searchingPlace) { result in
            switch result {
            case .success(let files):
                let filteredFiles = files.filter { file in
                    file.displayedName().lowercased().contains(name.lowercased())
                }
                completion(.success(filteredFiles))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func createFolder(at file: File, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        let path = dropboxPath(file: file)
        client.files.createFolderV2(path: path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(()))
        }
    }
    
    func newNameForCreationOfFolder(
        at file: File,
        newFolderName: String,
        completion: @escaping (Result<File, Error>) -> Void
    ) {
        var destinationFile: File
        if file == rootFolder {
            destinationFile = File(path: URL(fileURLWithPath: "/\(newFolderName)"), storageType: .dropbox)
        } else {
            destinationFile = file.makeSubfile(name: newFolderName, isDirectory: true)
        }
        self.correctFolderPath(file: &destinationFile)
        contents(of: file) { result in
            switch result {
            case .success(let files):
                var fileForChanges = destinationFile
                var numberOfFolder = 0
                repeat {
                    let suffixToName = numberOfFolder == 0 ? "" : " \(numberOfFolder)"
                    let newName = destinationFile.name + suffixToName
                    fileForChanges = fileForChanges.rename(name: newName)
                    self.correctFolderPath(file: &fileForChanges)
                    numberOfFolder += 1
                } while files.contains(fileForChanges)
                completion(.success(fileForChanges))
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
    }

    func rename(file: File, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let renamedFilePath = file.rename(name: newName).path.path
        let path = dropboxPath(file: file)
//        client.files.moveV2(fromPath: path, toPath: renamedFilePath).response { response, error in
//            if let error = error {
//                completion(.failure(Error(dropboxError: error)))
//                return
//            }
//            completion(.success(()))
//        }

        let template = FileProperties.PropertyFieldTemplate(name: "One", description_: "", type: .string_)

        client.file_properties.templatesAddForUser(name: "User", description_: "", fields: [template]).response {  (templateResult, error) in
            if let templateID = templateResult?.templateId {
                let field = FileProperties.PropertyField(name: "One", value: "Blue")
                let group = FileProperties.PropertyGroup(templateId: templateID, fields: [field])
                client.file_properties.propertiesAdd(path: path, propertyGroups: [group]).response { result, error  in
                    print(result ?? "No result from properties add")
                    print(error ?? "no error from properties add")
                }
                client.files.getMetadata(path: path, includeMediaInfo: true, includePropertyGroups: FileProperties.TemplateFilterBase.filterSome([templateID])).response { (data, error) in
                    print(data ?? "No data from getMetadata")
                    print(error ?? "No error from getMetadata")
                }
            }
            print(templateResult ?? "No result from templatesAddForUser")
            print(error ?? "no error from templatesAddForUser")
        }

//        let field = FileProperties.PropertyField(name: "Tags", value: "Blue")
//        let group = FileProperties.PropertyGroup(templateId: "ptid:IBksWnL9lHsAAAAAAAAA3A", fields: [field])
//        client.file_properties.propertiesAdd(path: path, propertyGroups: [group]).response { result, error  in
//            print(result ?? "No result from properties add")
//            print(error ?? "no error from properties add")
//        }
        
//        let field = FileProperties.PropertyField(name: "Tags", value: "Red")
//        let update = FileProperties.PropertyGroupUpdate(templateId: "ptid:IBksWnL9lHsAAAAAAAAA3A", addOrUpdateFields: [field])
//        client.file_properties.propertiesUpdate(path: path, updatePropertyGroups: [update]).response { result, error  in
//            print(result ?? "No result from properties update")
//            print(error ?? "no error from properties update")
//        }
        client.files.getMetadata(path: path, includeMediaInfo: true, includePropertyGroups: FileProperties.TemplateFilterBase.filterSome(["ptid:IBksWnL9lHsAAAAAAAAA3A"])).response { (data, error) in
            print(data ?? "No data from getMetadata")
            print(error ?? "No error from getMetadata")
        }
    }
    
    func copy(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        if files.count == 1 {
            guard let oneFile = files.last else { return }
            copyOne(file: oneFile, destination: destination, conflictResolver: conflictResolver, completion: completion)
        } else {
            copyBatch(files: files, destination: destination, conflictResolver: conflictResolver, completion: completion)
        }
    }

    func move(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        if files.count == 1 {
            guard let oneFile = files.last else { return }
            moveOne(file: oneFile, destination: destination, conflictResolver: conflictResolver, completion: completion)
        } else {
            moveBatch(files: files, destination: destination, conflictResolver: conflictResolver, completion: completion)
        }
    }
    
    func moveToTrash(filesToTrash: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        for file in filesToTrash {
            let path = dropboxPath(file: file)
            client.files.deleteV2(path: path).response { response, error in
                if let error = error {
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    func restoreFromTrash(
        filesToRestore: [File],
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let group = DispatchGroup()
        for file in filesToRestore {
            group.enter()
            let path = dropboxPath(file: file)
            client.files.listRevisions(path: path).response { response, error in
                if let error = error {
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                guard let lastRevision = response?.entries.last else {
                    print("No revisons")
                    return
                }
                client.files.restore(path: path, rev: lastRevision.rev).response { response, error in
                    defer { group.leave() }
                    if let error = error {
                        completion(.failure(Error(dropboxError: error)))
                        return
                    }
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion(.success(.finished))
        }
    }
    
    func deleteFile(files: [File], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        for file in files {
            let path = dropboxPath(file: file)
            client.files.permanentlyDelete(path: path).response { response, error in
                if let error = error {
                    print(error)
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    func cleanTrashFolder(fileForFileManager: File, completion: @escaping (Result<Void, Error>) -> Void) {
        contents(of: trashFolder) { result in
            switch result {
            case .success(let files):
                self.deleteFile(files: files, completion: completion)
            case .failure(let error):
                completion(.failure(Error(error: error)))
            }
        }
    }
    
    func makeFolderMonitor(file: File) -> FolderMonitor? {
        nil
    }
    
    func getFileAttributes(file: File, completion: @escaping (Result<FileAttributes, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        if file.folderAffiliation == .system(.trash) {
            return
        }
        var newFile = file
        correctFolderPath(file: &newFile)
        client.files.getMetadata(path: newFile.path.path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            if let result = response {
                switch result {
                case let fileMetadata as Files.FileMetadata:
                    self.getSizeOfFile(file: file) { result in
                        switch result {
                        case .success(let sizeOfFile):
                            completion(.success(FileAttributes(
                                size: sizeOfFile,
                                createdDate: fileMetadata.serverModified,
                                modifiedDate: fileMetadata.clientModified
                            )))
                        case .failure(let error):
                            completion(.failure(Error(error: error)))
                        }
                    }
                case _ as Files.FolderMetadata:
                    self.getSizeOfFolder(file: file) { result in
                        switch result {
                        case .success(let sizeOfFolder):
                            completion(.success(FileAttributes(
                                size: sizeOfFolder,
                                createdDate: nil,
                                modifiedDate: nil
                            )))
                        case .failure(let error):
                            completion(.failure(Error(error: error)))
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}

extension DropboxFileManager: LocalTemporaryFolderConnector {
    
    func copyToLocalTemporary(
        files: [File],
        completion: @escaping (Result<[URL], Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let group = DispatchGroup()
        var destinationFileURLs: [URL] = []
        var lastError: Error?
        for file in files {
            group.enter()
            let copyFilePath = dropboxPath(file: file)
            let destinationFile = File(
                path: SystemFileManger.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString, isDirectory: true),
                storageType: .local
            )
            FileManagerCommutator().createFolder(at: destinationFile) { result in
                switch result {
                case .success:
                    break
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
            let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
                return destinationFile.makeSubfile(name: file.name).path
            }
            client.files.download(path: copyFilePath, overwrite: true, destination: destination).response { response, error in
                defer { group.leave() }
                if let error = error {
                    lastError = Error(dropboxError: error)
                    return
                }
                if let result = response {
                    destinationFileURLs.append(result.1)
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            if let error = lastError {
                completion(.failure(error))
            } else {
                completion(.success(destinationFileURLs))
            }
        }
    }
    
    func saveFromLocalTemporary(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var filesCommitInfo = [URL: Files.CommitInfo]()
        
        for file in files {
            let fileUrl = file.path
            let uploadToPath = destination.makeSubfile(name: file.name).path.path
            filesCommitInfo[fileUrl] = Files.CommitInfo(path: uploadToPath, mode: .overwrite)
        }
        
        client.files.batchUploadFiles(
            fileUrlsToCommitInfo: filesCommitInfo,
            responseBlock: { uploadResults, finishBatchRequestError, fileUrlsToRequestErrors in
                
                if let finishBatchRequestError = finishBatchRequestError {
                    completion(.failure(Error(dropboxError: finishBatchRequestError)))
                    return
                }
                if let error = fileUrlsToRequestErrors.first?.value {
                    completion(.failure(Error(dropboxError: error)))
                    return
                }
                completion(.success(.finished))
            })
    }
    
    func getLocalFileURL(file: File, completion: @escaping (Result<URL, Error>) -> Void) {
        copyToLocalTemporary(files: [file]) { result in
            switch result {
            case .success(let urls):
                if let tempURL = urls.first {
                    completion(.success(tempURL))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Private

private extension DropboxFileManager {
    
    func correctFolderPath(file: inout File) {
//    TODO make extension for file
        if file.path.pathExtension == "" {
            file.path = file.path.appendingPathExtension(for: .folder)
        }
    }
    
    func updatedFile(file: File) -> File {
        var file = file
        updateFileActionsAndDeleteStatus(file: &file)
        updateFolderAffiliation(file: &file)
        return file
    }
    
    func updateFileActionsAndDeleteStatus(file: inout File) {
        if file == trashFolder {
            file.actions = FileAction.trashFolderActions
        } else if file.isFileIsSub(file: trashFolder) ||
                    file.isFileIsSub(file: trashFolder, isDirectory: true) ||
                    file.isDeleted {
            file.actions = [FileAction.restoreFromTrash]
            file.isDeleted = true
        } else {
            file.actions = FileAction.regularFolder
        }
    }
    
    func updateFolderAffiliation(file: inout File) {
        if file == rootFolder {
            file.folderAffiliation = .system(.root)
        } else if file == trashFolder {
            file.folderAffiliation = .system(.trash)
        } else {
            file.folderAffiliation = .user
        }
    }
    
    func copyOne(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let destinationFile = destination.makeSubfile(name: file.name)
        client.files.copyV2(fromPath: file.path.path, toPath: destinationFile.path.path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(.finished))
        }
    }
    
    func copyBatch(files: [File],
                   destination: File,
                   conflictResolver: NameConflictResolver,
                   completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var filesRelocationPaths: [Files.RelocationPath] = []
        for file in files {
            let copyFilePath = dropboxPath(file: file)
            let destinationFile = destination.makeSubfile(name: file.name)
            let destinationPath = dropboxPath(file: destinationFile)
            filesRelocationPaths.append(Files.RelocationPath(fromPath: copyFilePath, toPath: destinationPath))
        }
        client.files.copyBatchV2(entries: filesRelocationPaths).response { response, error in
            if let error = error {
                print(error)
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(.finished))
        }
    }
    
    func moveOne(
        file: File,
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let destinationFile = destination.makeSubfile(name: file.name)
        client.files.moveV2(fromPath: file.path.path, toPath: destinationFile.path.path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(.finished))
        }
    }
    
    func moveBatch(files: [File],
                   destination: File,
                   conflictResolver: NameConflictResolver,
                   completion: @escaping (Result<OperationResult, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var filesRelocationPaths: [Files.RelocationPath] = []
        for file in files {
            let copyFilePath = dropboxPath(file: file)
            let destinationFile = destination.makeSubfile(name: file.name)
            filesRelocationPaths.append(Files.RelocationPath(fromPath: copyFilePath, toPath: destinationFile.path.path))
        }
        client.files.moveBatchV2(entries: filesRelocationPaths).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(.finished))
        }
    }
    
    func dropboxPath(file: File) -> String {
        return file == rootFolder ? "" : file.path.path
    }
    
    func contentOfTrashFolder(file: File, completion: @escaping (Result<[File], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        var path = ""
        if dropboxPath(file: file) != trashFolder.path.path {
            path = dropboxPath(file: file)
        }
        client.files.listFolder(path: path, recursive: true, includeDeleted: true).response { response, error in
            if let error = error {
                print(path)
                completion(.failure(Error(dropboxError: error)))
                return
            }
            var files: [File] = []
            if let result = response {
                for fileInResult in result.entries.reversed() {
                    switch fileInResult {
                    case let deletedMetadata as Files.DeletedMetadata:
                        var fileInFolder = File(
                            path: URL(fileURLWithPath: deletedMetadata.pathDisplay!),
                            storageType: .dropbox
                        )
                        self.correctFolderPath(file: &fileInFolder)
                        if fileInFolder.isFolder() {
                            let isFileInOtherTrashedFolder = files.contains {
                                fileInFolder.hasParent(file: $0)
                           }
                            if isFileInOtherTrashedFolder {
                                continue
                            }
                        }
                        fileInFolder.isDeleted = true
                        fileInFolder = self.updatedFile(file: fileInFolder)
                        files.append(fileInFolder)
                    default:
                        continue
                    }
                }
            }
            completion(.success(files))
        }
    }
    
    func addTrashFolderToRoot(file: File, files: inout [File]) {
        if file == self.rootFolder {
            trashFolder.folderAffiliation = .system(.trash)
            self.correctFolderPath(file: &trashFolder)
            files.append(self.trashFolder)
        }
    }
    
    func getSizeOfFile(file: File, completion: @escaping (Result<Double, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = dropboxPath(file: file)
        
        client.files.getMetadata(path: path).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            if let result = response {
                switch result {
                case let fileMetadata as Files.FileMetadata:
                    completion(.success(Double(fileMetadata.size)))
                default:
                    break
                }
            }
        }
    }
    
    func getSizeOfFolder(file: File, completion: @escaping (Result<Double, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = dropboxPath(file: file)
        var newFile = file
        correctFolderPath(file: &newFile)
        
        client.files.listFolder(path: path, recursive: true).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            if let result = response {
                var size = 0.0
                for fileInResult in result.entries {
                    switch fileInResult {
                    case let metaDataSize as Files.FileMetadata:
                        size += Double(metaDataSize.size)
                    default:
                        continue
                    }
                }
                completion(.success(size))
            }
        }
    }

    func contentInSearching(of file: File, completion: @escaping (Result<[File], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = dropboxPath(file: file)

        client.files.listFolder(path: path, recursive: true).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            var files: [File] = []

            if let result = response {
                for fileInResult in result.entries {
                    var fileInFolder = File(
                        path: URL(fileURLWithPath: fileInResult.pathDisplay!),
                        storageType: .dropbox
                    )
                    self.correctFolderPath(file: &fileInFolder)
                    fileInFolder = self.updatedFile(file: fileInFolder)
                    files.append(fileInFolder)
                }
            }
            completion(.success(files))
        }
    }
    
    func getFilesDependOnSearchPlace(
        file: File,
        searchingPlace: SearchingPlace,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        switch searchingPlace {
        case .currentStorage:
            contentInSearching(of: rootFolder, completion: completion)
        case .currentFolder:
            contentInSearching(of: file, completion: completion)
        case .currentTrash:
            contentOfTrashFolder(file: file, completion: completion)
        case .allStorages:
            contentInSearching(of: rootFolder, completion: completion)
        }
    }
}
