//
//  FolderMonitor.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 07.07.2023.
//

import Foundation

class FolderMonitor {
    
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
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor, eventMask: .write, queue: .main)
        folderMonitorSource?.setEventHandler { [weak self] in
                self?.folderDidChange?()
        }
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.monitoredFolderFileDescriptor)
            strongSelf.monitoredFolderFileDescriptor = -1
            strongSelf.folderMonitorSource = nil
        }
        folderMonitorSource?.resume()
        
        // instead of unwrapping variable each time, write like this:
        /// ```
        /// let value = makeValue()
        /// self.value = value
        /// value.callFun1()
        /// value.callFun1()
        /// ```
    }
    
    func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}
