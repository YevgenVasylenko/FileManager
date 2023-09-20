//
//  FileView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FileView: View {
    enum Style {
        case grid
        case list
        case info
    }
    
    private let file: File
    private let style: Style
    private let infoPresented: Binding<Bool>
    
    init(file: File, style: Style, infoPresented: Binding<Bool>) {
        self.file = file
        self.style = style
        self.infoPresented = infoPresented
    }
    
    var body: some View {
        container {
            imageOfFile(imageName: file.imageName)
            nameOfFile(fileName: file.displayedName())
        }
//        .padding()
//        .frame(width: width())
        .popover(isPresented: infoPresented) {
            FileInfoView(file: file)
        }
    }
}

// MARK: - Private

private extension FileView {
    
    func imageOfFile(imageName: String) -> some View {
        return Image(imageName)
//            .resizable()
            .frame(width: 75, height: 75)
    }
    
    func nameOfFile(fileName: String) -> some View {
        return Text(fileName)
            .font(.headline)
            .lineLimit(lineLimit())
    }
    
    func container(@ViewBuilder content: () -> some View) -> some View {
        Group {
            switch style {
            case .grid:
                VStack(content: content)
            case .list:
                HStack(content: content)
            case .info:
                VStack(content: content)
            }
        }
    }
    
    func width() -> CGFloat {
        switch style {
        case .grid:
            return 80
        case .list:
            return 30
        case .info:
            return 200
        }
    }
    
    func lineLimit() -> Int? {
        switch style {
        case .grid:
            return 2
        case .list:
            return nil
        case .info:
            return nil
        }
    }
}


//
//struct FileView_Previews: PreviewProvider {
//    static var previews: some View {
//        FileView(file: PreviewFiles.downloadsFolder)
//    }
//}


