//
//  EngineBuilder.swift
//  EngineBuilder
//
//  Created by Chris Ballinger on 5/28/18.
//

import Foundation
import AppFolder
import CryptoSwift
import CommonCrypto

public enum Result<T> {
    case success(T)
    case failure(Error)
}

public enum BuildError: Error {
    case downloadError
    case fileError(Error)
    case networkError(Error)
    case checksumMismatch
}

/// URL is path to built engine
public typealias BuildResult = Result<(Engine, URL)>
public typealias BuildCompletion = (BuildResult)->Void
/// URL is to path of downloaded Source URL resource
private typealias DownloadResult = Result<(URL)>
private typealias DownloadCompletion = (DownloadResult)->Void
/// URL is to file checked, String is computed SHA256
private typealias ChecksumResult = Result<(URL, String)>
private typealias ChecksumCompletion = (ChecksumResult)->Void

public final class EngineBuilder {
    private let engine: Engine
    private let outputDirectory: URL
    private let engineCache = AppFolder.Library.Caches.WineskinEngineCache
    private let sourceType: Engine.Source.SourceType = .binaryWineHQ
    private let arch: [Engine.Source.Arch] = [.i386, .x86_64]
    
    public init(engine: Engine,
                outputDirectory: URL) throws {
        self.engine = engine
        self.outputDirectory = outputDirectory
        
        if !FileManager.default.fileExists(atPath: outputDirectory.path) {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        if !FileManager.default.fileExists(atPath: engineCache.url.path) {
            try FileManager.default.createDirectory(at: engineCache.url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    public func build(_ completion: @escaping BuildCompletion) {
        guard let binarySource = engine.binary(arch: arch) else {
            completion(.failure(EngineError.engineNotFound))
            return
        }
        downloadIfNeeded(source: binarySource) { (result) in
            switch result {
            case .success(let url):
                print("Source URL ready: \(url)")
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func downloadIfNeeded(source: Engine.Source, _ completion: @escaping DownloadCompletion) {
        
        let fileName = source.url.lastPathComponent
        let destination = engineCache.url.appendingPathComponent(fileName)
        
        let checkIntegrity = {
            self.checkFileIntegrity(fileURL: destination, sha256: source.sha256) { (result) in
                switch result {
                case .success:
                    completion(.success(destination))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        if FileManager.default.fileExists(atPath: destination.path) {
            print("Found cached download at \(destination)")
            checkIntegrity()
            return
        }
        
        print("Downloading binary at \(source.url) to \(destination)")
        let downloadTask = URLSession.shared.downloadTask(with: source.url) { (url, response, error) in
            guard let url = url else {
                if let error = error {
                    print("Could not download file: \(error)")
                    completion(.failure(BuildError.networkError(error)))
                } else {
                    print("Could not download file")
                    completion(.failure(BuildError.downloadError))
                }
                return
            }

            do {
                try FileManager.default.moveItem(at: url, to: destination)
            } catch {
                print("Could not move engine binary from \(url) to \(destination)")
                completion(.failure(BuildError.fileError(error)))
                return
            }
            print("Download successful to \(destination)")
            
            checkIntegrity()
        }
        downloadTask.resume()
    }
    
    private func checkFileIntegrity(fileURL: URL, sha256: String, _ completion: @escaping ChecksumCompletion) {
        print("Running checksum of \(fileURL), expecting \(sha256)")
        do {
            let digest = try SHA256(url: fileURL)
            let expected = Data(hex: sha256)
            let digestHex = digest.toHexString()
            if digest == expected {
                print("Checksum match: \(fileURL) \(digestHex)")
                completion(.success((fileURL, digestHex)))
            } else {
                print("Checksum mismatch! \(fileURL) \(digestHex) != \(sha256)")
                completion(.failure(BuildError.checksumMismatch))
            }
        } catch {
            completion(.failure(BuildError.fileError(error)))
        }
    }
}


extension Library.Application_Support {
    
    final class Wineskin : Directory { }
    
    var Wineskin: Wineskin {
        return subdirectory()
    }
    
}

extension Library.Caches {
    
    final class WineskinEngineCache : Directory { }
    
    var WineskinEngineCache: WineskinEngineCache {
        return subdirectory()
    }
    
}

// https://stackoverflow.com/a/49878022/805882
private func SHA256(url: URL) throws -> Data  {
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
