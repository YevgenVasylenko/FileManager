//
//  LocalFolderMonitor.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 07.07.2023.
//

import Foundation

class LocalFolderMonitor: FolderMonitor {
    
    private var monitoredFolderFileDescriptor: CInt = -1
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    private let url: Foundation.URL
    
    var folderDidChange: (() -> Void)?
    
    init(url: Foundation.URL) {
        self.url = url
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        let folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor, eventMask: .write, queue: .main)
        self.folderMonitorSource = folderMonitorSource
        folderMonitorSource.setEventHandler { [weak self] in
            self?.folderDidChange?()
        }
        folderMonitorSource.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.monitoredFolderFileDescriptor)
            strongSelf.monitoredFolderFileDescriptor = -1
            strongSelf.folderMonitorSource = nil
        }
        folderMonitorSource.resume()
    }
    
    func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}
