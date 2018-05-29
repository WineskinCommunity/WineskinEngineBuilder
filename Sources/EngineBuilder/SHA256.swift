//
//  SHA256.swift
//  EngineBuilder
//
//  Created by Chris Ballinger on 5/28/18.
//

import Foundation
import CommonCrypto

extension URL {
    /// Only for local File URLs. Do not try this on remote URLs.
    public func sha256Digest() throws -> Data {
        return try SHA256(url: self)
    }
}


// https://stackoverflow.com/a/49878022/805882
public func SHA256(url: URL) throws -> Data  {
    let bufferSize = 1024 * 1024
    // Open file for reading:
    let file = try FileHandle(forReadingFrom: url)
    defer {
        file.closeFile()
    }
    
    // Create and initialize SHA256 context:
    var context = CC_SHA256_CTX()
    CC_SHA256_Init(&context)
    
    // Read up to `bufferSize` bytes, until EOF is reached, and update SHA256 context:
    while autoreleasepool(invoking: {
        // Read up to `bufferSize` bytes
        let data = file.readData(ofLength: bufferSize)
        if data.count > 0 {
            data.withUnsafeBytes {
                _ = CC_SHA256_Update(&context, $0, numericCast(data.count))
            }
            // Continue
            return true
        } else {
            // End of file
            return false
        }
    }) { }
    
    // Compute the SHA256 digest:
    var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
    digest.withUnsafeMutableBytes {
        _ = CC_SHA256_Final($0, &context)
    }
    
    return digest
}
