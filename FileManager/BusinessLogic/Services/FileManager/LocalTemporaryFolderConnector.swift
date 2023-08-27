//
//  LocalTemporaryFolderConnector.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 17.08.2023.
//

import Foundation

protocol LocalTemporaryFolderConnector {
    
    func copyToLocalTemporary(
        files: [File],
        completion: @escaping (Result<[URL], Error>) -> Void
    )
    
    func saveFromLocalTemporary(
        files: [File],
        destination: File,
        conflictResolver: NameConflictResolver,
        isForOneFile: Bool,
        completion: @escaping (Result<OperationResult, Error>) -> Void
    )
    
    func getLocalFileURL(file: File, completion: @escaping (Result<URL, Error>) -> Void)
}
