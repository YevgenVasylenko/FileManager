//
//  FileDisplayedName.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 19.08.2023.
//

import Foundation

extension File {
    
    func displayedName() -> String {
        if self.name == "/" {
            return R.string.localizable.dropbox.callAsFunction()
        }
        if self.name == "root" {
            return R.string.localizable.root.callAsFunction()
        }
        switch self.folderAffiliation {
        case .user:
            return self.name
        case .system(.trash):
            return R.string.localizable.trash.callAsFunction()
        case .system(.download):
            return R.string.localizable.downloads.callAsFunction()
        }
    }
}
