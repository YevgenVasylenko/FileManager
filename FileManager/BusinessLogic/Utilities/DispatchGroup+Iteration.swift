//
//  DispatchGroup+Iteration.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 19.01.2024.
//

import Foundation

extension DispatchGroup {
    static func perform<Value>(
        value: [Value],
        action: @escaping (Value, _ completion: @escaping () -> Void) -> Void,
        completion: @escaping () -> Void
    ) {
        let group = DispatchGroup()

        for input in value {
            group.enter()
            action(input, group.leave)
        }

        group.notify(queue: .main, execute: completion)
    }
}
