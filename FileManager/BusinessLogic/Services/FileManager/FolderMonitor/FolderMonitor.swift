//
//  FolderMonitor.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 01.08.2023.
//

import Foundation

protocol FolderMonitor: AnyObject {
    var folderDidChange: (() -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
}
