//
//  ConflictResolver.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 30.06.2023.
//

import Foundation

enum ConflictNameResult {
    case cancel
    case replace
    case newName
}

protocol NameConflictResolver {
    func resolve(completion: @escaping (ConflictNameResult) -> Void)
}

struct NameConflictResolverMock: NameConflictResolver {
    var mockResult: ConflictNameResult!

    func resolve(completion: @escaping (ConflictNameResult) -> Void) {
        completion(mockResult)
    }

}