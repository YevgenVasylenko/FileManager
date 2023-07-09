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
        switch fileType {
        case .folder:
            return R.image.folder.name
        case .image:
            return R.image.image.name
        case .text:
            return R.image.pdf.name
        }
    }
}
