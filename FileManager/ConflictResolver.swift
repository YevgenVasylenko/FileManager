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

protocol ConflictResolver {
    func resolve() -> ConflictNameResult
}

struct ConflictResolverMock: ConflictResolver {
    var mockResult: ConflictNameResult!
    
    func resolve() -> ConflictNameResult {
        mockResult
    }
}
