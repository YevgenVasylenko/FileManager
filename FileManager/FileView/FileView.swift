//
//  FileView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FileView: View {

    var file: File
        
    var body: some View {

            VStack {
                Image(file.imageName)
                    .resizable()
                    .frame(width: 50, height: 50)
                
                Text(file.name)
                    .font(.headline)
                
                FileContextMenuView(file: file)
            }
//            Spacer()
    }
}

struct FileView_Previews: PreviewProvider {
    static let fileManager = LocalFileManager(fileManagerRootPath: LocalFileMangerRootPath())
    
    static var object = fileManager.downloadsFolder
    
    static var previews: some View {
        FileView(file: self.object)
    }
//        .previewLayout(.fixed(width: 300, height: 70))
}
