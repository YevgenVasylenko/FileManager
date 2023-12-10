//
//  FileManager.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 04.07.2023.
//

import Foundation

typealias SystemFileManger = Foundation.FileManager

enum OperationResult {
    case cancelled
    case finished
}

protocol FileManager {
    
    func contents(of file: File, completion: @escaping (Result<[File], Error>) -> Void)
    
    func contentBySearchingName(
        searchingPlace: SearchingPlace,
        file: File, name: String,
        completion: @escaping (Result<[File], Error>) -> Void
    )
    
    func createFolder(at file: File, completion: @escaping (Result<Void, Error>) -> Void)
    
    func newNameForCreationOfFolder(
        at file: File,
        newFolderName: String,
        completion: @escaping (Result<File, Error>) -> Void)
    
    func rename(file: File, newName: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    func copy(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    )

    func move(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    )
   
    func moveToTrash(filesToTrash: [File], completion: @escaping (Result<Void, Error>) -> Void)
    
    func restoreFromTrash(
        filesToRestore: [File],
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    )
    
    func cleanTrashFolder(fileForFileManager: File, completion: @escaping (Result<Void, Error>) -> Void)

    func deleteFile(files: [File], completion: @escaping (Result<Void, Error>) -> Void)
    
    func makeFolderMonitor(file: File) -> FolderMonitor?
    
    func getFileAttributes(file: File, completion: @escaping (Result<FileAttributes, Error>) -> Void)

    func addTags(to file: File, tags: [Tag], completion: @escaping (Result<Void, Error>) -> Void)

    func getActiveTagIds(on file: File, completion: @escaping (Result<[String], Error>) -> Void)

    func filesWithTag(tag: Tag, completion: @escaping (Result<[File], Error>) -> Void)
}


