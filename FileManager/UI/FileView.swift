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
    private let tagsPresented: Binding<Bool>

    init(file: File, style: Style, infoPresented: Binding<Bool>, tagsPresented: Binding<Bool>) {
        self.file = file
        self.style = style
        self.infoPresented = infoPresented
        self.tagsPresented = tagsPresented
    }
    
    var body: some View {
        container {
            imageOfFile(imageName: file.imageName)
            nameOfFile(fileName: file.displayedName())
            setOfTagsImage()
        }
        .frame(width: width())
        .popover(isPresented: infoPresented) {
            FileInfoView(file: file)
        }
        .popover(isPresented: tagsPresented) {
            TagsMenuView(file: file)
        }
    }
}

// MARK: - Private

private extension FileView {
    
    func imageOfFile(imageName: String) -> some View {
        return Image(imageName)
            .resizable()
            .frame(width: 65, height: 65)
    }
    
    func nameOfFile(fileName: String) -> some View {
            return Text(fileName)
            .font(.headline)
            .lineLimit(lineLimit())
    }

    func imageOfTags(tag: Tag) -> some View {
        ZStack {
            Image(systemName: "circle.fill")
                .foregroundColor(Color(uiColor: UIColor(rgb: tag.color?.rawValue ?? 0x000000)))
            Image(systemName: "circle")
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    func setOfTagsImage() -> some View {
        ZStack {
            ForEach(Array(file.getTags().enumerated()), id: \.element) { index, tag in
                imageOfTags(tag: tag)
                    .offset(x: offsetCalculations(numberOfCircle: index, amountOfCircles: file.getTags().count))
            }
        }
    }

    @ViewBuilder
    func container(@ViewBuilder content: () -> some View) -> some View {
        switch style {
        case .grid:
            VStack(alignment: .center, content: content)
        case .list:
            HStack(content: content)
        case .info:
            VStack(content: content)
        }
    }
    
    func width() -> CGFloat? {
        switch style {
        case .grid:
            return 80
        case .list:
            return nil
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

    func offsetCalculations(numberOfCircle: Int, amountOfCircles: Int) -> CGFloat {
       return CGFloat((Float(numberOfCircle) - (Float(amountOfCircles) - 1)/2) * 5)
    }
}
