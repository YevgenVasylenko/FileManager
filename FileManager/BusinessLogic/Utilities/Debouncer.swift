//
//  Debouncer.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 09.11.2023.
//

import Foundation

class Debouncer {
    private var searchTimer: Timer?

    func perform(timeInterval: Double, completion: @escaping () -> Void) {
        searchTimer?.invalidate()

        searchTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { _ in
            completion()
        })
    }
}
