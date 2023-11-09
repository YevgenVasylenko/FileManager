//
//  Debouncer.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 09.11.2023.
//

import Foundation

class Debouncer {
    var searchTimer: Timer?

    func perform(completion: @escaping () -> Void) {
        self.searchTimer?.invalidate()

        searchTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] (timer) in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                completion()
            }
          })
    }
}
