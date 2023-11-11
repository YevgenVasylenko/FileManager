//
//  Debouncer.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 09.11.2023.
//

import Foundation

class Debouncer {
    var searchTimer: Timer?

    func perform(timeInterval: Double, completion: @escaping () -> Void) {
        self.searchTimer?.invalidate()

        searchTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { [weak self] (timer) in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                completion()
            }
          })
    }
}
