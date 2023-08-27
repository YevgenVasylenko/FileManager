//
//  View+Utilities.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 11.07.2023.
//

import Foundation
import SwiftUI

extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        let localizedAlertError = error.wrappedValue
        return alert(isPresented: .constant(localizedAlertError != nil), error: localizedAlertError) { _ in
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
