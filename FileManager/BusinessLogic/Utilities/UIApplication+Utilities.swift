//
//  UIApplication+Utilities.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 21.08.2023.
//

import UIKit

extension UIApplication {
    func firstKeyWindow() -> UIWindow? {
        UIApplication.shared
            .connectedScenes
            .lazy
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
    }
}

