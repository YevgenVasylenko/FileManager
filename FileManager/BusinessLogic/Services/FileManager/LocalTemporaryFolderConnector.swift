//
//  LocalTemporaryFolderConnector.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 17.08.2023.
//

import Foundation

protocol LocalTemporaryFolderConnector {
    
    func copyBatchOfFilesToLocalTemporary(
        files: [File],
        completion: @escaping (Result<[URL], Error>) -> Void
    )

    func moveBatchOfFilesToLocalTemporary(
        files: [File],
        completion: @escaping (Result<[URL], Error>) -> Void
    )
    
    func saveFilesFromLocalTemporary(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    )
    
    func getLocalFileURL(file: File, completion: @escaping (Result<URL, Error>) -> Void)
}
