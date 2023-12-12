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

        static let propertyFieldName = "Tags"
        static var templateNameForUser: String {
            guard let name = Bundle.main.bundleIdentifier else { return "" }
            return name
        }
    }
    
    private(set) var rootFolder: File

    init () {
        rootFolder = File(
            path: URL(fileURLWithPath: Constants.root),
            storageType: .dropbox
        )

        rootFolder = updatedFile(file: rootFolder)
    }
}

extension DropboxFileManager: FileManager {
    
    func contents(of file: File, completion: @escaping (Result<[File], Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }
        let path = dropboxPath(file: file)

        client.files.listFolder(path: path).response { response, error in
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
   
    func contentBySearchingName(
        searchingPlace: SearchingPlace,
        file: File,
        name: String,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        getFilesDependOnSearchPlace(currentFolder: file, searchingPlace: searchingPlace) { result in
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
        client.files.moveV2(fromPath: path, toPath: renamedFilePath).response { response, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            completion(.success(()))
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
        // Not supported
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
        // Not supported
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

    func addTags(to file: File, tags: [Tag], completion: @escaping (Result<Void, Error>) -> Void) {
        getTemplateId { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success(let id):
                guard let client = DropboxClientsManager.authorizedClient else {
                    completion(.failure(.unknown))
                    return
                }
                let path = self.dropboxPath(file: file)
                let tagIds = tags.map { $0.id.uuidString }
                let encodedTagIds = AttributesCoding.fromArrayToString(array: tagIds)
                let field = FileProperties.PropertyField(name: Constants.propertyFieldName, value: encodedTagIds)
                let update = FileProperties.PropertyGroupUpdate(templateId: id, addOrUpdateFields: [field])
                let group = FileProperties.PropertyGroup(templateId: id, fields: [field])

                client.files.getMetadata(
                    path: path,
                    includeMediaInfo: true,
                    includePropertyGroups: FileProperties
                        .TemplateFilterBase
                        .filterSome([id])).response { response, error in
                            if let error = error {
                                completion(.failure(Error(dropboxError: error)))
                                return
                            }
                            if let response {
                                self.addOrUpdateProperties(
                                    path: path,
                                    groupToUpdate: update,
                                    groupToAdd: group,
                                    fileMetadata: response,
                                    templateId: id,
                                    completion: completion)
                            }
                        }
            }
        }
    }

    func getActiveTagIds(on file: File, completion: @escaping (Result<[String], Error>) -> Void) {
        getTemplateId { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success(let id):
                guard let client = DropboxClientsManager.authorizedClient else {
                    completion(.failure(.unknown))
                    return
                }
                let path = self.dropboxPath(file: file)
                client.files.getMetadata(path: path, includeMediaInfo: true, includePropertyGroups: FileProperties.TemplateFilterBase.filterSome([id])).response { data, error in
                    if let error = error {
                        completion(.failure(Error(dropboxError: error)))
                        return
                    }
                    if let data {
                        switch data {
                        case let fileMetadata as Files.FileMetadata:
                            completion(.success(AttributesCoding.fromStringToArray(string: fileMetadata.propertyGroups?.first?.fields.first?.value ?? "")))
                        case let folderMetadata as Files.FolderMetadata:
                            completion(.success(AttributesCoding.fromStringToArray(string: folderMetadata.propertyGroups?.first?.fields.first?.value ?? "")))
                        default:
                            completion(.failure(.unknown))
                        }
                    }
                }
            }
        }
    }

    func filesWithTag(tag: Tag, completion: @escaping (Result<[File], Error>) -> Void) {
        allFilesInside(rootFolder) { result in
            switch result {
            case .success(let files):
                var filesWithTag: [File] = []
                var error: Error?
                let group = DispatchGroup()
                for file in files {
                    group.enter()
                    self.getActiveTagIds(on: file) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let tagIds):
                            if tagIds.contains(tag.id.uuidString) {
                                filesWithTag.append(file)
                            }
                        case .failure(let _error):
                            error = _error
                        }
                    }
                }
                group.notify(queue: .main) {
                    if let error {
                        completion(.failure(error))
                    } else {
                        completion(.success(filesWithTag))
                    }
                }
            case .failure(let _error):
                completion(.failure(_error))
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

    func isStorageLogged() -> Bool {
        DropboxLoginManager.isLogged
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
        file.actions = FileAction.regularFile
    }
    
    func updateFolderAffiliation(file: inout File) {
        if file == rootFolder {
            file.folderAffiliation = .system(.root)
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

    func allFilesInside(_ file: File, completion: @escaping (Result<[File], Error>) -> Void) {
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
        currentFolder: File,
        searchingPlace: SearchingPlace,
        completion: @escaping (Result<[File], Error>) -> Void
    ) {
        switch searchingPlace {
        case .currentStorage:
            allFilesInside(rootFolder, completion: completion)
        case .currentFolder:
            allFilesInside(currentFolder, completion: completion)
        case .currentTrash:
            //TO DO make smth
            break
        case .allStorages:
            allFilesInside(rootFolder, completion: completion)
        }
    }

    func getTemplateId(completion: @escaping (Result<String, Error>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }

        client.file_properties.templatesListForUser().response { result, error in
            if let error = error {
                completion(.failure(Error(dropboxError: error)))
                return
            }
            if let ids = result?.templateIds {
                if ids.isEmpty {
                    let template = FileProperties.PropertyFieldTemplate(name: Constants.propertyFieldName, description_: "", type: .string_)
                    client.file_properties.templatesAddForUser(name: Constants.templateNameForUser, description_: "", fields: [template]).response { result, error in
                        if let error = error {
                            completion(.failure(Error(dropboxError: error)))
                            return
                        }
                        if let id = result?.templateId {
                            completion(.success(id))
                        }
                    }
                } else {
                    completion(.success(ids.last ?? ""))
                }
            }
        }
    }

    func addProperties(
        path: String,
        groupToAdd: FileProperties.PropertyGroup,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }

        client.file_properties.propertiesAdd(
            path: path,
            propertyGroups: [groupToAdd]
        ).response { result, error in
            if result != nil {
                completion(.success(()))
                return
            }
            if let error {
                completion(.failure(Error(dropboxError: error)))
            }
        }
    }

    func updateProperties(
        path: String,
        groupToUpdate: FileProperties.PropertyGroupUpdate,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(.failure(.unknown))
            return
        }

        client.file_properties.propertiesUpdate(
            path: path,
            updatePropertyGroups: [groupToUpdate]
        ).response { result, error in
            if result != nil {
                completion(.success(()))
                return
            }
            if let error {
                completion(.failure(Error(dropboxError: error)))
            }
        }
    }

    func addOrUpdateProperties(
        path: String,
        groupToUpdate: FileProperties.PropertyGroupUpdate,
        groupToAdd: FileProperties.PropertyGroup,
        fileMetadata: Files.Metadata,
        templateId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        switch fileMetadata {
        case let fileMetadata as Files.FileMetadata:
            if (fileMetadata.propertyGroups ?? []).contains(where: { group in
                group.templateId == templateId
            }) {
                updateProperties(path: path, groupToUpdate: groupToUpdate, completion: completion)
            } else {
                addProperties(path: path, groupToAdd: groupToAdd, completion: completion)
            }
        case let folderMetadata as Files.FolderMetadata:
            if folderMetadata.propertyGroups!.contains(where: { group in
                group.templateId == templateId
            }) {
                updateProperties(path: path, groupToUpdate: groupToUpdate, completion: completion)
            } else {
                addProperties(path: path, groupToAdd: groupToAdd, completion: completion)
            }
        default:
            completion(.failure(.unknown))
        }
    }
}
