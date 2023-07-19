//
//  EnvironmentUtils.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 09.07.2023.
//

import Foundation

enum EnvironmentUtils {
    static var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

        
