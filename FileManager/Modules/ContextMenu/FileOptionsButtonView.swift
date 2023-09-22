//
//  FileOptionsButtonView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 07.07.2023.
//

import SwiftUI

struct FileOptionsButtonView: View {
    var delegate: (FileAction) -> Void
    let file: File
    
    init(file: File, delegate: @escaping (FileAction) -> Void) {
        self.file = file
        self.delegate = delegate
    }
    
    var body: some View {
        Group {
            if !file.actions.isEmpty {
                Menu {
                    Group {
                        ForEach(file.actions, id: \.self) { action in

                            switch action {
                            case .rename:
                                renameButton()
                            case .move:
                                moveButton()
                            case .copy:
                                copyButton()
                            case .moveToTrash:
                                moveToTrashButton()
                            case .restoreFromTrash:
                                restoreFromTrash()
                            case .delete:
                                deleteButton()
                            case .clean:
                                cleanButton()
                            case .info:
                                infoButton()
                            }

                        }
                    }
                    .buttonStyle(.plain)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                }
            }
            Spacer()
        }
    }
}

private extension FileOptionsButtonView {
    func renameButton() -> some View {
        Button {
            delegate(.rename)
        } label: {
            Label(R.string.localizable.rename.callAsFunction(), systemImage: "character.cursor.ibeam")
        }
    }
    
    func moveButton() -> some View {
        Button {
            delegate(.move)
        } label: {
            Label(R.string.localizable.move_to.callAsFunction(), systemImage: "arrow.right.doc.on.clipboard")
        }
    }
    
    func copyButton() -> some View {
        Button {
            delegate(.copy)
        } label: {
            Label(R.string.localizable.copy_to.callAsFunction(), systemImage: "square.and.arrow.up.on.square")
        }
    }
    
    func moveToTrashButton() -> some View {
        Button {
            delegate(.moveToTrash)
        } label: {
            Label(R.string.localizable.move_to_trash.callAsFunction(), systemImage: "rectangle.portrait.and.arrow.forward")
            Label("", systemImage: "trash")
        }
    }
    
    func restoreFromTrash() -> some View {
        Button {
            delegate(.restoreFromTrash)
        } label: {
            Label(R.string.localizable.restore.callAsFunction(), systemImage: "tray.and.arrow.up")
        }
    }
    
    func deleteButton() -> some View {
        Button {
            delegate(.delete)
        } label: {
            Label(R.string.localizable.delete.callAsFunction(), systemImage: "trash")
        }
    }
    
    func cleanButton() -> some View {
        Button {
            delegate(.clean)
        } label: {
            Label(R.string.localizable.clean.callAsFunction(), systemImage: "paintbrush.pointed")
        }
    }
    
    func infoButton() -> some View {
        Button {
            delegate(.info)
        } label: {
            Label(R.string.localizable.info.callAsFunction(), systemImage: "info.circle")
        }
    }
}

struct FileOptionsButtonView_Previews: PreviewProvider {
    static var previews: some View {
        FileOptionsButtonView(file: PreviewFiles.trashFolder) { action in
            switch action {
            case .rename:
                break
            case .move:
                break
            case .copy:
                break
            case .moveToTrash:
                break
            case .restoreFromTrash:
                break
            case .delete:
                break
            case .clean:
                break
            case .info:
                break
            }
        }
    }
}

