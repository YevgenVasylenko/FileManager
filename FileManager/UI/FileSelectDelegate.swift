//
//  FileSelectDelegate.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 24.10.2023.
//

import Foundation

struct FileSelectDelegate {
    let type: FileActionType
    let selectedFiles: [File]
    let selected: (File?) -> Void
}
