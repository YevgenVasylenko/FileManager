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
            FileView(
                file: viewModel.state.file,
                style: .info,
                infoPresented: .constant(false),
                tagsPresented: .constant(false)
            )
            Spacer()
            Text(R.string.localizable.info())
            Spacer()
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

// MARK: - Private

private extension FileInfoView {
    func typeOfFile() -> some View {
        HStack {
            Text(R.string.localizable.type())
                .font(.headline)
            Spacer()
            Text(viewModel.state.file.path.pathExtension.isEmpty ?
                 R.string.localizable.folder() :
                    viewModel.state.file.path.pathExtension)
        }
    }
    
    func sizeOfFile() -> some View {
        HStack {
            Text(R.string.localizable.size())
                .font(.headline)
            Spacer()
            Text(bytesCalculator(size:viewModel.state.file.attributes?.size))
        }
    }
    
    func dateOfCreation() -> some View {
        HStack {
            Text(R.string.localizable.created())
                .font(.headline)
            Spacer()
            Text(viewModel.state.file.attributes?.createdDate?.formatted() ?? "-")
        }
    }
    
    func dateOfLastModifier() -> some View {
        HStack {
            Text(R.string.localizable.modified())
                .font(.headline)
            Spacer()
            Text(viewModel.state.file.attributes?.modifiedDate?.formatted() ?? "-")
        }
    }
    
    func bytesCalculator(size: Double?) -> String {
        guard let number = size else { return "" }
        var newNumber = 0.0
        if number / 1000 < 1 {
            return number.description + R.string.localizable.b()
        } else if number / 1000000 < 1 {
            newNumber = number / 1000
            return keepThreeDigits(number: newNumber).description + R.string.localizable.kb()
        } else if number / 1000000000 < 1 {
            newNumber = number / 1000000
            return keepThreeDigits(number: newNumber).description + R.string.localizable.mb()
        } else {
            newNumber = number / 10000000000
            return keepThreeDigits(number: newNumber).description + R.string.localizable.gb()
        }
    }
    
    func keepThreeDigits(number: Double) -> Double {
        let countOfWholeNumbers = Int(number).description.count
        if countOfWholeNumbers == 3 {
            return Double(Int(number))
        } else if countOfWholeNumbers == 2 {
            return Double(round(10 * number) / 10)
        } else {
            return Double(round(100 * number) / 100)
        }
    }
}
