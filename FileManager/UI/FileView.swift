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
                .frame(width: 75, height: 75)
            Text(file.name)
                .font(.headline)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(width: 75)
    }
}

struct FileView_Previews: PreviewProvider {
    static var previews: some View {
        FileView(file: PreviewFiles.downloadsFolder)
    }
}


