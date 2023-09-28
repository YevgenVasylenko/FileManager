//
//  ConflictResolver.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 30.06.2023.
//

import Foundation

enum ConflictNameResult: CaseIterable {
    case replace
    case newName
    case cancel
    case error
}

protocol NameConflictResolver {
    func resolve(conflictedFile: File, placeOfConflict: File, completion: @escaping (ConflictNameResult) -> Void)
}

struct NameConflictResolverMock: NameConflictResolver {
    var mockResult: ConflictNameResult!

    func resolve(conflictedFile: File, placeOfConflict: File, completion: @escaping (ConflictNameResult) -> Void) {
        completion(mockResult)
    }
}
