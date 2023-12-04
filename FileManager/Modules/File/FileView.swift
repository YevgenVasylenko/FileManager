//
//  FileView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 22.06.2023.
//

import SwiftUI

struct FileView: View {
 
    @StateObject
    private var viewModel: FileViewModel

    init(file: File, style: FileViewModel.Style, infoPresented: Binding<Bool>, tagsPresented: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: FileViewModel(
            file: file,
            style: style,
            infoPresented: infoPresented,
            tagsPresented: tagsPresented
        ))
    }
    
    var body: some View {
        container {
            imageOfFile(imageName: viewModel.file.imageName)
            nameOfFile(fileName: viewModel.file.displayedName())
            setOfTagsImage()
        }
        .frame(width: width())
        .popover(isPresented: viewModel.infoPresented) {
            FileInfoView(file: viewModel.file)
        }
        .popover(isPresented: viewModel.tagsPresented) {
            TagsMenuView(file: viewModel.file)
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
            ForEach(Array(viewModel.state.tags.enumerated()), id: \.element) { index, tag in
                imageOfTags(tag: tag)
                    .offset(x: offsetCalculations(numberOfCircle: index, amountOfCircles: viewModel.state.tags.count))
            }
        }
    }

    @ViewBuilder
    func container(@ViewBuilder content: () -> some View) -> some View {
        switch viewModel.style {
        case .grid:
            VStack(alignment: .center, content: content)
        case .list:
            HStack(content: content)
        case .info:
            VStack(content: content)
        }
    }
    
    func width() -> CGFloat? {
        switch viewModel.style {
        case .grid:
            return 80
        case .list:
            return nil
        case .info:
            return 200
        }
    }
    
    func lineLimit() -> Int? {
        switch viewModel.style {
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
