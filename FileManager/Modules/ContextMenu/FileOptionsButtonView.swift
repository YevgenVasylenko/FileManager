//
//  FileOptionsButtonView.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 07.07.2023.
//

import SwiftUI

struct FileOptionsButtonView: View {
//    @ObservedObject var viewModel: FileOptionsButtonViewModel
    var delegate: (FileAction) -> Void?
    let file: File
    
    init(file: File, delegate: @escaping (FileAction) -> Void) {
//        self.viewModel = FileOptionsButtonViewModel(file: file)
        self.file = file
        self.delegate = delegate
    }
    
    var body: some View {
        Group {
//            if !viewModel.state.file.actions.isEmpty {
            if !file.actions.isEmpty {
                Menu {
                    Group {
//                        ForEach(viewModel.state.file.actions, id: \.self) { action in
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
                            case .delete:
                                deleteButton()
                            case .clean:
                                cleanButton()
                            }
                        }
                    }
                    
                    .buttonStyle(.plain)
                } label: {
                    Text("...")
                }
            }
            Spacer()
        }
//        .destinationPopoverFileOption(viewModule: viewModel)
//        .conflictAlertFileOption(viewModule: viewModel)
//        .errorAlert(error: $viewModel.state.error)
    }
}

private extension FileOptionsButtonView {
    func renameButton() -> some View {
        Button {
//            viewModel.rename()
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
//            viewModel.copy()
        } label: {
            Label(R.string.localizable.copy_to.callAsFunction(), systemImage: "square.and.arrow.up.on.square")
        }
    }
    
    func moveToTrashButton() -> some View {
        Button {
//            viewModel.moveToTrash()
            delegate(.moveToTrash)
        } label: {
            Label(R.string.localizable.move_to_trash.callAsFunction(), systemImage: "rectangle.portrait.and.arrow.forward")
            Label("", systemImage: "trash")
        }
    }
    
    func deleteButton() -> some View {
        Button {
//            viewModel.delete()
            delegate(.delete)
        } label: {
            Label(R.string.localizable.delete.callAsFunction(), systemImage: "trash")
        }
    }
    
    func cleanButton() -> some View {
        Button {
            delegate(.clean)
//            viewModel.clear()
        } label: {
            Label(R.string.localizable.clean.callAsFunction(), systemImage: "paintbrush.pointed")
        }
    }
}

//struct FileOptionsButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        FileOptionsButtonView(file: PreviewFiles.trashFolder)
//    }
//}

extension View {
    func conflictAlertFileOption(viewModule: FileOptionsButtonViewModel) -> some View {
        let nameConflict = viewModule.state.nameConflict
        return alert("File with name \(viewModule.state.nameConflict?.file?.name ?? "") is exist", isPresented: .constant(nameConflict != nil)) {
            HStack {
                Button("Cancel") {
                    viewModule.userConflictResolveChoice(nameResult: .cancel)
                }
                Button("Replace") {
                    viewModule.userConflictResolveChoice(nameResult: .replace)
                }
                Button("New Name") {
                    viewModule.userConflictResolveChoice(nameResult: .newName)
                }
            }
        }
    }
    
//    func destinationPopoverFileOption(viewModule: FileOptionsButtonViewModel) -> some View {
//        let fileActionType = viewModule.state.fileActionType
//        return sheet(isPresented: .constant(fileActionType != nil)) {
//            RootView(fileSelectDelegate: FileSelectDelegate(type: fileActionType ?? .move, selected: { file in
//                viewModule.moveOrCopyWithUserChosen(folder: file)
//            }))
//        }
//    }
}
