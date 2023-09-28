//
//  View+Utilities.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 11.07.2023.
//

import Foundation
import SwiftUI

extension View {
    
    func destinationPopover(
        actionType: FileActionType?,
        files: [File],
        moveOrCopyToFolder: @escaping (File?) -> Void
    ) -> some View {
        let fileActionType = actionType
        return sheet(isPresented: .constant(fileActionType != nil)) {
            RootView(
                fileSelectDelegate: FileSelectDelegate(
                    type: fileActionType ?? .move,
                    selectedFiles: files,
                    selected: { file in
                        moveOrCopyToFolder(file)
                    }))
            .interactiveDismissDisabled()
        }
    }
    
    func conflictPopover(
        conflictName: NameConflict?,
        resolveConflictWithUserChoice: @escaping (ConflictNameResult) -> Void
    ) -> some View {
        let conflictAlertTitlePart1 = R.string.localizable.conflictAlertTitlePart1.callAsFunction()
        let placeOfConflict = (conflictName?.placeOfConflict?.displayedName() ?? "")
        let conflictAlertTitlePart2 = R.string.localizable.conflictAlertTitlePart2.callAsFunction()
        let conflictedFile = (conflictName?.conflictedFile?.name ?? "")
        let filteredCases = ConflictNameResult.allCases.filter({ $0 != .error })
        
        return alert(conflictAlertTitlePart1 + placeOfConflict + conflictAlertTitlePart2 + conflictedFile, isPresented: .constant(conflictName != nil)
        ) {
            HStack {
                ForEach(filteredCases, id: \.self) { nameResult in
                    Button(nameForConflictResult(nameResult: nameResult)) {
                        resolveConflictWithUserChoice(nameResult)
                    }
                }
            }
        }
    }
    
    func nameForConflictResult(nameResult: ConflictNameResult) -> String {
        switch nameResult {
        case .cancel:
            return R.string.localizable.cancel.callAsFunction()
        case .replace:
            return R.string.localizable.replace.callAsFunction()
        case .newName:
            return R.string.localizable.new_name.callAsFunction()
        case .error:
            return ""
        }
    }
    
    func errorAlert(error: Binding<Error?>) -> some View {
        let localizedAlertError = error.wrappedValue
        return alert(
            isPresented: .constant(localizedAlertError != nil),
            error: localizedAlertError
        ) { _ in
            Button(R.string.localizable.ok.callAsFunction()) {
             error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
    
    func unreadableFileAlert(isShowing: Binding<Bool>, presentation: Binding<PresentationMode>) -> some View {
        return alert(R.string.localizable.unreadableFile.callAsFunction(), isPresented: isShowing) {
            Button(R.string.localizable.ok.callAsFunction()) {
                presentation.wrappedValue.dismiss()
            }
        }
    }
}

extension Error {
    var recoverySuggestion: String? {
        switch self {
        case .nameExist:
            return R.string.localizable.file_with_same_name_is_already_exist.callAsFunction()
        case .unknown:
            return R.string.localizable.try_smth_else.callAsFunction()
        case .dropbox:
            return R.string.localizable.try_smth_else.callAsFunction()
        }
    }
}
