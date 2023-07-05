//
//  FIleManagerRootPath.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 29.06.2023.
//

import Foundation

protocol FileManagerRootPath {
    var documentsURL: URL { get }
}

struct LocalFileMangerRootPath: FileManagerRootPath {
    var documentsURL: URL = SystemFileManger.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}

struct TestFileMangerRootPath: FileManagerRootPath {
    var documentsURL: URL = SystemFileManger.default.temporaryDirectory
}
