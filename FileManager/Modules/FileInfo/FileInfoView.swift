//
//  FileInfoView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 28.08.2023.
//

import SwiftUI

struct FileInfoView: View {
    
    @ObservedObject
    private var viewModel: FileInfoViewModel
    
    init(file: File) {
        viewModel = FileInfoViewModel(file: file)
    }
    
    var body: some View {
        VStack {
            FileView(file: viewModel.state.file, infoPresented: .constant(false))
            Text(R.string.localizable.info.callAsFunction())
            VStack {
                typeOfFile()
                sizeOfFile()
                dateOfCreation()
                dateOfLastModifier()
            }
        }
        .padding()
    }
}

private extension FileInfoView {
    func typeOfFile() -> some View {
        HStack {
            Text(R.string.localizable.type.callAsFunction())
            Spacer()
            Text(viewModel.state.file.path.pathExtension)
        }
    }
    
    func sizeOfFile() -> some View {
        HStack {
            Text(R.string.localizable.size.callAsFunction())
            Spacer()
            Text(viewModel.state.fileAttributes?.size.description ?? "")
        }
    }
    
    func dateOfCreation() -> some View {
        HStack {
            Text(R.string.localizable.created.callAsFunction())
            Spacer()
            Text(viewModel.state.fileAttributes?.createdDate?.formatted() ?? "-")
        }
    }
    
    func dateOfLastModifier() -> some View {
        HStack {
            Text(R.string.localizable.modified.callAsFunction())
            Spacer()
            Text(viewModel.state.fileAttributes?.modifiedDate?.formatted() ?? "-")
        }
    }
    
    func bytesCalculator(size: Double?) -> String {
        guard let number = size else { return "" }
        var newNumber = 0.0
        if number / 1000 < 1 {
            return number.description + R.string.localizable.b.callAsFunction()
        } else if number / 1000000 < 1 {
            newNumber = number / 1000
            return Int(newNumber).description + R.string.localizable.kb.callAsFunction()
        } else if number / 1000000000 < 1 {
            newNumber = number / 1000000
            return Int(newNumber).description + R.string.localizable.mb.callAsFunction()
        } else if number / 1000000000000 < 1 {
            newNumber = number / 10000000000
            return newNumber.description + R.string.localizable.gb.callAsFunction()
        } else {
            return ""
        }
    }
}

//struct FileInfoView_Previews: PreviewProvider {
//    static var previews: some View {
//        FileInfoView(observedPresentation: .constant(true))
//    }
//}
