//
//  FIle+Utilities.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 21.08.2023.
//

import SwiftUI

extension File {
    enum Constants {
        static let image = ["png", "gif", "ico", "svg", "webp", "tiff", "jpeg"]
        static let documents = ["pdf", "xls", "xlsx", "doc", "ppt", "docx", "rtf"]
        static let audio = ["wav", "mp3"]
        static let video = ["mov", "mp4"]
        static let other = ["json", "html", "xml", "csv"]
    }
    
    enum ObjectType {
        case folder
        case trashFolder
        case image
        case documents
        case audio
        case video
        case other
        case unknown
    }
    
    func typeDefine() -> ObjectType {
        if self.isFolder() {
            switch self.folderAffiliation {
            case .user:
                return .folder
            case .system(.trash):
                return .trashFolder
            case .system(.download):
                return .folder
            }
        } else if Constants.image.contains(self.path.pathExtension) {
            return .image
        } else if Constants.documents.contains(self.path.pathExtension) {
            return .documents
        } else if Constants.audio.contains(self.path.pathExtension) {
            return .audio
        } else if Constants.video.contains(self.path.pathExtension) {
            return .video
        } else if Constants.other.contains(self.path.pathExtension) {
            return .other
        } else {
            return .unknown
        }
    }
}
