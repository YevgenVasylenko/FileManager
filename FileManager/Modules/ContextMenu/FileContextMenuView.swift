//
//  FileContextMenuView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 07.07.2023.
//

import SwiftUI

struct FileContextMenuView: View {
    @ObservedObject var viewModel: ContextMenuViewModel
    
    init(file: File) {
        self.viewModel = ContextMenuViewModel(file: file)
    }
    
    var body: some View {
        
        Text("...")
            .contextMenu {
                ForEach(viewModel.state.file.actions, id: \.self) { action in
                    switch action {
                        
                    case .rename:
                        renameButton()
                    case .move:
                        Button {
                            print("Enable geolocation")
                        } label: {
                            Label(R.string.localizable.move_to.callAsFunction(), systemImage: "arrow.right.doc.on.clipboard")
                        }
                    case .copy:
                        Button {
                            print("Enable geolocation")
                        } label: {
                            Label(R.string.localizable.copy_to.callAsFunction(), systemImage: "square.and.arrow.up.on.square")
                        }
                    case .moveToTrash:
                        Button {
                            print("Enable geolocation")
                        } label: {
                            Label(R.string.localizable.move_to_trash.callAsFunction(), systemImage: "rectangle.portrait.and.arrow.forward")
                            Label("", systemImage: "trash")
                        }
                    case .delete:
                        Button {
                            viewModel.delete()
                        } label: {
                            Label(R.string.localizable.delete.callAsFunction(), systemImage: "trash")
                        }
                    case .clean:
                        Button {
//                            viewModel.cleanTrash()
                        } label: {
                            Label(R.string.localizable.clean.callAsFunction(), systemImage: "paintbrush.pointed")
                        }
                    }
                }
            }
    }
}

private extension FileContextMenuView {
    func renameButton() -> some View {
        Button {
            print("Change country setting")
        } label: {
            Label(R.string.localizable.rename.callAsFunction(), systemImage: "character.cursor.ibeam")
        }
    }
}
struct FileContextMenu_Previews: PreviewProvider {

    static var previews: some View {
        FileContextMenuView(file: PreviewFiles.trashFolder)
    }
}
