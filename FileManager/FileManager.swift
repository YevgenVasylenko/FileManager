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
    
    func contents(of file: File, completion: (Result<[File], Error>) -> Void)
    
    func createFolder(at file: File, completion: (Result<Void, Error>) -> Void)
    
    func copyFile(
        fileToCopy: File,
        destination: File,
        conflictResolver: ConflictResolver,
        completion: (Result<OperationResult, Error>) -> Void)
    
    func moveFile(
        fileToCopy: File,
        destination: File,
        conflictResolver: ConflictResolver,
        completion: (Result<Void, Error>) -> Void)
    
    func moveToTrash(fileToTrash: File, completion: (Result<File, Error>) -> Void)
    
    func deleteFile(file: File, completion: (Result<Void, Error>) -> Void)
}
