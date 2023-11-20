//
//  URL+ExtendedAttributes.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 19.11.2023.
//

import Foundation

extension URL {

    /// Get extended attribute.
    func extendedAttribute(forName name: String) throws -> Data  {

        let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in

            // Determine attribute size:
            let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }

            // Create buffer with required size:
            var data = Data(count: length)

            // Retrieve attribute:
            let result =  data.withUnsafeMutableBytes { [count = data.count] in
                getxattr(fileSystemPath, name, $0.baseAddress, count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
            return data
        }
        return data
    }

    /// Set extended attribute.
    func setExtendedAttribute(data: Data, forName name: String) throws {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }

    /// Remove extended attribute.
    func removeExtendedAttribute(forName name: String) throws {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = removexattr(fileSystemPath, name, 0)
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }

    /// Get list of all extended attributes.
    func listExtendedAttributes() throws -> [String] {

        let list = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> [String] in
            let length = listxattr(fileSystemPath, nil, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }

            // Create buffer with required size:
            var namebuf = Array<CChar>(repeating: 0, count: length)

            // Retrieve attribute list:
            let result = listxattr(fileSystemPath, &namebuf, namebuf.count, 0)
            guard result >= 0 else { throw URL.posixError(errno) }

            // Extract attribute names:
            let list = namebuf.split(separator: 0).compactMap {
                $0.withUnsafeBufferPointer {
                    $0.withMemoryRebound(to: UInt8.self) {
                        String(bytes: $0, encoding: .utf8)
                    }
                }
            }
            return list
        }
        return list
    }

    /// Helper function to create an NSError from a Unix errno.
    private static func posixError(_ err: Int32) -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
                       userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
    }
}

/// Keep sample 
struct Sample {

    let file: File

    let attr1 = "com.myCompany.myAttribute"
    let attr2 = "com.myCompany.otherAttribute"

    let data1 = Data([1, 2, 3, 4])
    let data2 = Data([5, 6, 7, 8, 9])

    func trySample(file: File) {

        do {
            // Set attributes:
            try file.path.setExtendedAttribute(data: data1, forName: attr1)
            try file.path.setExtendedAttribute(data: data2, forName: attr2)

            // List attributes:
            let list = try file.path.listExtendedAttributes()
            print(list)
            // ["com.myCompany.myAttribute", "com.myCompany.otherAttribute", "other"]

            let data1a = try file.path.extendedAttribute(forName: attr1)
            print(data1a as NSData)
            // <01020304>

            // Remove attributes
            for attr in list {
                try file.path.removeExtendedAttribute(forName: attr)
            }

        } catch let error {
            print(error.localizedDescription)
        }
    }
}
