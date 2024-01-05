//
//  AttributesCoding.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 03.12.2023.
//

import Foundation

enum AttributesCoding {

    static func fromArrayToData(array: [String]) -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: array)
        } catch {
            return Data()
        }
    }

    static func fromDataToArray(data: Data) -> [String] {
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            return []
        }
    }

    static func fromArrayToString(array: [String]) -> String {
        let data = fromArrayToData(array: array)
        if let string = String(data: data, encoding: String.Encoding.utf8) {
            return string
        } else {
            return ""
        }
    }

    static func fromStringToArray(string: String) -> [String] {
        let data = Data(string.utf8)
        return fromDataToArray(data: data)
    }
}
