//
//  DropboxFolderMonitor.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 14.08.2023.
//

import Foundation
import SwiftyDropbox

class DropboxFolderMonitor: FolderMonitor {
    private let url: Foundation.URL

    var folderDidChange: (() -> Void)?
    
    init(url: Foundation.URL) {
        self.url = url
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard let client = DropboxClientsManager.authorizedClient else {
            return
        }
        
        client.files.listFolder(path: url.path).response { response, error in
            guard let isHasMore = response?.hasMore else { return }
            if isHasMore {
                client.files.listFolderContinue(cursor: response?.cursor ?? "").response { response, error in
                    if let action = self.folderDidChange {
                        action()
                    }
                }
            }
        }
    }
    
    func stopMonitoring() {
        
    }
    
    
}
