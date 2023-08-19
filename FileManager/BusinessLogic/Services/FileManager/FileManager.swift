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
        isForOneFile: Bool,
        completion: @escaping (Result<OperationResult, Error>) -> Void)

    func move(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        isForOneFile: Bool,
        completion: @escaping (Result<OperationResult, Error>) -> Void)
   
    func moveToTrash(filesToTrash: [File], completion: @escaping (Result<Void, Error>) -> Void)
    
    func restoreFromTrash(filesToRestore: [File], completion: @escaping (Result<Void, Error>) -> Void)
    
    func cleanTrashFolder(fileForFileManager: File, completion: @escaping (Result<Void, Error>) -> Void)

    func deleteFile(files: [File], completion: @escaping (Result<Void, Error>) -> Void)
    
    func makeFolderMonitor(file: File) -> FolderMonitor?
}


