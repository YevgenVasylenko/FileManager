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

enum F {
    static func perform<Value, Result>(
        values: ArraySlice<Value>,
        completedResult: Result,
        action: @escaping (
            _ value: Value,
            _ completion: @escaping (Swift.Result<Result, Error>) -> Void
        ) -> (),
        completion: @escaping (Swift.Result<Result, Error>) -> Void
    ) {

        guard let value = values.first else {
            completion(.success(completedResult))
            return
        }

        action(value) { result in
            switch result {
            case .failure(let failure):
                completion(.failure(failure))
            case .success:
                let values = values.dropFirst()
                perform(values: values, completedResult: completedResult, action: action, completion: completion)
            }
        }
    }
}
