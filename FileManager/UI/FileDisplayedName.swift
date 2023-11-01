//
//  FileDisplayedName.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 19.08.2023.
//

import Foundation

extension File {
    
    func displayedName() -> String {
        switch self.folderAffiliation {
        case .user:
            return self.name
        case .system(.root):
            if self.storageType == .dropbox {
                return R.string.localizable.dropbox()
            }
            if self.storageType == .local {
                return R.string.localizable.root()
            }
            return self.name
        case .system(.trash):
            return R.string.localizable.trash()
        case .system(.download):
            return R.string.localizable.downloads()
        }
    }
}
