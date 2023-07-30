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
}

