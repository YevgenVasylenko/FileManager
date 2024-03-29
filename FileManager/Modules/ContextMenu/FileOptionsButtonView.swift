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

    @ViewBuilder
    var body: some View {
        if !file.actions.isEmpty {
            Menu {
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
                    case .tags:
                        tagsButton()
                    case .info:
                        infoButton()
                    }
                    
                }
                .buttonStyle(.plain)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .padding()
            }
        }
    }
}

// MARK: - Private

private extension FileOptionsButtonView {
    func renameButton() -> some View {
        Button {
            delegate(.rename)
        } label: {
            Label(R.string.localizable.rename(), systemImage: "character.cursor.ibeam")
        }
    }
    
    func moveButton() -> some View {
        Button {
            delegate(.move)
        } label: {
            Label(R.string.localizable.move_to(), systemImage: "arrow.right.doc.on.clipboard")
        }
    }
    
    func copyButton() -> some View {
        Button {
            delegate(.copy)
        } label: {
            Label(R.string.localizable.copy_to(), systemImage: "square.and.arrow.up.on.square")
        }
    }
    
    func moveToTrashButton() -> some View {
        Button {
            delegate(.moveToTrash)
        } label: {
            Label(R.string.localizable.move_to_trash(), systemImage: "rectangle.portrait.and.arrow.forward")
            Label("", systemImage: "trash")
        }
    }
    
    func restoreFromTrash() -> some View {
        Button {
            delegate(.restoreFromTrash)
        } label: {
            Label(R.string.localizable.restore(), systemImage: "tray.and.arrow.up")
        }
    }
    
    func deleteButton() -> some View {
        Button {
            delegate(.delete)
        } label: {
            Label(R.string.localizable.delete(), systemImage: "trash")
        }
    }
    
    func cleanButton() -> some View {
        Button {
            delegate(.clean)
        } label: {
            Label(R.string.localizable.clean(), systemImage: "paintbrush.pointed")
        }
    }

    func tagsButton() -> some View {
        Button {
            delegate(.tags)
        } label: {
            Label(R.string.localizable.tags(), systemImage: "tag")
        }
    }
    
    func infoButton() -> some View {
        Button {
            delegate(.info)
        } label: {
            Label(R.string.localizable.info(), systemImage: "info.circle")
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
            case .tags:
                break
            case .info:
                break
            }
        }
    }
}

