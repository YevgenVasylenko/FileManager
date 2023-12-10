//
//  URL+ExtendedAttributes.swift
//  FileManager
//
//  Created by Yevgen Vasylenko on 19.11.2023.
//

import Foundation

extension URL {
    func extendedAttribute(forName name: String) -> Data {
        let data = try? extendedAttributeWithError(forName: name)
        return data ?? Data()
    }

    func setExtendedAttribute(data: Data, forName name: String) {
        try? setExtendedAttributeWithError(data: data, forName: name)
    }
}

private extension URL {
    func extendedAttributeWithError(forName name: String) throws -> Data {

        let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in

            let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }

            var data = Data(count: length)

            let result =  data.withUnsafeMutableBytes { [count = data.count] in
                getxattr(fileSystemPath, name, $0.baseAddress, count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
            return data
        }
        return data
    }

    func setExtendedAttributeWithError(data: Data, forName name: String) throws {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }

    func removeExtendedAttributeWithError(forName name: String) throws {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = removexattr(fileSystemPath, name, 0)
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }

    func listExtendedAttributesWithError() throws -> [String] {

        let list = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> [String] in
            let length = listxattr(fileSystemPath, nil, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }

            var namebuf = Array<CChar>(repeating: 0, count: length)

            let result = listxattr(fileSystemPath, &namebuf, namebuf.count, 0)
            guard result >= 0 else { throw URL.posixError(errno) }

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
    
    static func posixError(_ err: Int32) -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
                       userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
    }
}

