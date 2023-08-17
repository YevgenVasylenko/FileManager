//
//  FileView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FileView: View {
    
    var file: File
    
    init(file: File) {
        self.file = file
    }
    
    var body: some View {
        VStack {
            imageOfFile(imageName: file.imageName)
            nameOfFile(fileName: file.displayedName())
        }
        .frame(width: 80)
    }
}

// MARK: - Private

private extension FileView {
    func imageOfFile(imageName: String) -> some View {
        return Image(imageName)
            .resizable()
            .frame(width: 75, height: 75)
    }
    
    func nameOfFile(fileName: String) -> some View {
        return Text(fileName)
            .font(.headline)
            .lineLimit(2, reservesSpace: false)
    }
}

struct FileView_Previews: PreviewProvider {
    static var previews: some View {
        FileView(file: PreviewFiles.downloadsFolder)
    }
}


