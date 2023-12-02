//
//  File+UI.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 08.07.2023.
//

import Foundation

extension File {
    
    var imageName: String {
        imageNameDefine()
    }
    
    func imageNameDefine() -> String {
        switch fileType() {
        case .folder:
            return R.image.folder.name
        case .image:
            return R.image.image.name
        case .documents:
            return R.image.documents.name
        case .audio:
            return R.image.audio.name
        case .video:
            return R.image.video.name
        case .other:
            return R.image.other.name
        case .unknown:
            return R.image.unknown.name
        case .trashFolder:
            return R.image.emptyTrash.name
        }
    }

    func getTags() -> [Tag] {
        return self.path.listExtendedAttributesForFile().compactMap { tagName in
            for tag in TagManager.shared.tags {
                if tag.name == tagName {
                    return tag
                }
            }
            return nil
        }
    }
}
