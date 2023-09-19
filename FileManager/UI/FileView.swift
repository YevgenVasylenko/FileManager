//
//  FileView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FileView: View {
    
    private let file: File
    var isSelfForInfo: Bool
    private let infoPresented: Binding<Bool>
    
    init(file: File, isSelfForInfo: Bool = false, infoPresented: Binding<Bool>) {
        self.file = file
        self.isSelfForInfo = isSelfForInfo
        self.infoPresented = infoPresented
    }
    
    var body: some View {
        VStack {
            imageOfFile(imageName: file.imageName)
            nameOfFile(fileName: file.displayedName())
        }
        .frame(width: !isSelfForInfo ? 80 : 200)
        .popover(isPresented: infoPresented) {
            FileInfoView(file: file)
        }
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
            .lineLimit(!isSelfForInfo ? 2 : nil)
    }
}


//
//struct FileView_Previews: PreviewProvider {
//    static var previews: some View {
//        FileView(file: PreviewFiles.downloadsFolder)
//    }
//}


