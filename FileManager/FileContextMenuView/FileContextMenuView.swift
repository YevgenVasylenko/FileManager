//
//  FileContextMenuView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 07.07.2023.
//

import SwiftUI

struct FileContextMenuView: View {
    @ObservedObject var fileContextMenu: FileContextMenuViewModel
    
    init(file: File) {
        self.fileContextMenu = FileContextMenuViewModel(file: file)
    }
    
    var body: some View {
        Text("...")
            .contextMenu {
                Button {
                    print("Change country setting")
                } label: {
                    Label(R.string.localizable.rename.callAsFunction(), systemImage: "character.cursor.ibeam")
                }

                Button {
                    print("Enable geolocation")
                } label: {
                    Label(R.string.localizable.move_to.callAsFunction(), systemImage: "arrow.right.doc.on.clipboard")
                }
                
                Button {
                    print("Enable geolocation")
                } label: {
                    Label(R.string.localizable.copy_to.callAsFunction(), systemImage: "square.and.arrow.up.on.square")
                }
                
                Button {
                    fileContextMenu.delete()
                } label: {
                    Label(R.string.localizable.delete.callAsFunction(), systemImage: "trash")
                }
            }
    }
}

struct FileContextMenu_Previews: PreviewProvider {
    static var documentsFolder = File(path: SystemFileManger.default.urls(for: .documentDirectory, in: .userDomainMask).first!)
    
    static var previews: some View {
        FileContextMenuView(file: documentsFolder)
    }
}
