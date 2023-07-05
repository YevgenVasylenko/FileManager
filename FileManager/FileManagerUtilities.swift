//
//  FileManagerUtilities.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 30.06.2023.
//

import Foundation

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var isFailure: Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }
    
}
