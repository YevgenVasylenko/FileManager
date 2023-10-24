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
        actionType: Binding<FileActionType?>,
        files: [File],
        moveOrCopyToFolder: @escaping (File?) -> Void
    ) -> some View {
        sheet(item: actionType) { actionType in
            RootView(
                fileSelectDelegate: FileSelectDelegate(
                    type: actionType,
                    selectedFiles: files,
                    selected: moveOrCopyToFolder
                )
            )
            .interactiveDismissDisabled()
        }
    }
    
    func conflictPopover(
        conflictName: NameConflict?,
        resolveConflictWithUserChoice: @escaping (ConflictNameResult) -> Void
    ) -> some View {
        let conflictAlertTitlePart1 = R.string.localizable.conflictAlertTitlePart1()
        let placeOfConflict = (conflictName?.placeOfConflict?.displayedName() ?? "")
        let conflictAlertTitlePart2 = R.string.localizable.conflictAlertTitlePart2()
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
    
    func deleteConfirmationPopover(
        isShowing: Binding<Bool>,
        deletingConfirmed: @escaping () -> Void
    ) -> some View {
        alert(R.string.localizable.sureToDelete(), isPresented: isShowing) {
            Button(R.string.localizable.delete(), role: .destructive) {
                deletingConfirmed()
            }
        } message: {
            Text(R.string.localizable.deleteForever())
        }

    }
    
    func nameForConflictResult(nameResult: ConflictNameResult) -> String {
        switch nameResult {
        case .cancel:
            return R.string.localizable.cancel()
        case .replace:
            return R.string.localizable.replace()
        case .newName:
            return R.string.localizable.new_name()
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
            Button(R.string.localizable.ok()) {
             error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
    
    func unreadableFileAlert(isShowing: Binding<Bool>, presentation: Binding<PresentationMode>) -> some View {
        return alert(R.string.localizable.unreadableFile(), isPresented: isShowing) {
            Button(R.string.localizable.ok()) {
                presentation.wrappedValue.dismiss()
            }
        }
    }
}

extension Error {
    var recoverySuggestion: String? {
        switch self {
        case .nameExist:
            return R.string.localizable.file_with_same_name_is_already_exist()
        case .unknown, .dropbox:
            return R.string.localizable.unknown_error()
        }
    }
}
