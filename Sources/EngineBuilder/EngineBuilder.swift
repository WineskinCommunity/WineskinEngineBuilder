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
    case extractError(String)
    case tarArchiveError(String)
    case p7zipNotInstalled
    case p7zipError(String)
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
    private let tempDirectory: URL
    
    deinit {
        cleanup()
    }
    
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
        
        let uuid = UUID().uuidString
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(uuid)
        if !FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        self.tempDirectory = tempDirectory
    }
    
    private func cleanup() {
        do {
            if FileManager.default.fileExists(atPath: self.tempDirectory.path) {
                try FileManager.default.removeItem(at: self.tempDirectory)
            }
        } catch {
            print("Cleanup error: \(error)")
        }
    }
    
    public func build(_ completion: @escaping BuildCompletion) {
        guard let binarySource = engine.binary(arch: arch) else {
            completion(.failure(EngineError.engineNotFound))
            return
        }
        download(source: binarySource) { [weak self] (result) in
            guard let sself = self else { return }
            switch result {
            case .success(let url):
                print("Source URL ready: \(url)")
                do {
                    let usrDir = try sself.extractTarGz(fileURL: url)
                    let wsWineBundle = try sself.createWswineBundle(usrDir: usrDir)
                    let tarArchive = try sself.createTarArchive(wswineBundle: wsWineBundle)
                    let enginePath = try sself.create7zipArchive(tarArchive: tarArchive)
                    completion(.success((sself.engine, enginePath)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// extracts fileURL to a temp directory
    private func extractTarGz(fileURL: URL) throws -> URL {
        let destinationDirectory = self.tempDirectory
        let fileToExtract = fileURL

        let process = Process()
        process.launchPath = "/usr/bin/tar"
        process.arguments = ["-xf", fileToExtract.path, "--directory", destinationDirectory.path]
        
        let errPipe = Pipe()
        process.standardError = errPipe
        
        process.launch()
        
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let errString = String(data: errData, encoding: .utf8) ?? ""
        
        process.waitUntilExit()
        
        let status = process.terminationStatus
        guard status == 0 else {
            throw BuildError.extractError(errString)
        }
        let usrDir = destinationDirectory.appendingPathComponent("usr")
        guard FileManager.default.fileExists(atPath: usrDir.path) else {
            throw BuildError.extractError("File \(usrDir) does not exist")
        }
        return usrDir
    }
    
    
    private func createWswineBundle(usrDir: URL) throws -> URL {
        print("Creating wswine.bundle...")
        let versionFileName = "version"
        let versionPath = usrDir.appendingPathComponent(versionFileName)
        try engine.name.write(to: versionPath, atomically: true, encoding: .utf8)
        let wswineBundle = "wswine.bundle"
        let wswinePath = usrDir.deletingLastPathComponent().appendingPathComponent(wswineBundle)
        try FileManager.default.moveItem(at: usrDir, to: wswinePath)
        return wswinePath
    }
    
    private func createTarArchive(wswineBundle: URL) throws -> URL {
        let destinationDirectory = self.tempDirectory
        let outArchiveName = "\(engine.name).tar"
        let outArchive = destinationDirectory.appendingPathComponent(outArchiveName)
        print("Creating tar archive \(outArchive)"...)

        //-C /path/to/folder
        // tar -C /path/to/folder -cvjf /path/for/acrhive.tar.bz2 source
        

        let process = Process()
        process.launchPath = "/usr/bin/tar"
        process.arguments = ["-C", destinationDirectory.path, "-cf", outArchive.path, wswineBundle.lastPathComponent]
        
        let errPipe = Pipe()
        process.standardError = errPipe
        
        process.launch()
        
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let errString = String(data: errData, encoding: .utf8) ?? ""
        
        process.waitUntilExit()
        
        let status = process.terminationStatus
        guard status == 0 else {
            throw BuildError.tarArchiveError(errString)
        }
        guard FileManager.default.fileExists(atPath: outArchive.path) else {
            throw BuildError.tarArchiveError("File \(outArchive) does not exist")
        }
        return outArchive
    }
    
    private func create7zipArchive(tarArchive: URL) throws -> URL {
        let destinationDirectory = self.tempDirectory
        let outArchiveName = "\(engine.name).tar.7z"
        let outArchive = destinationDirectory.appendingPathComponent(outArchiveName)
        
        let p7zipPath = "/usr/local/bin/7za"
        guard FileManager.default.fileExists(atPath: p7zipPath) else {
            throw BuildError.p7zipNotInstalled
        }

        let process = Process()
        process.launchPath = p7zipPath
        process.arguments = ["a", outArchive.path, tarArchive.path]
        
        let errPipe = Pipe()
        process.standardError = errPipe
        
        process.launch()
        
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let errString = String(data: errData, encoding: .utf8) ?? ""
        
        process.waitUntilExit()
        
        let status = process.terminationStatus
        guard status == 0 else {
            throw BuildError.p7zipError(errString)
        }
        guard FileManager.default.fileExists(atPath: outArchive.path) else {
            throw BuildError.p7zipError("File \(outArchive) does not exist")
        }
        return outArchive
    }
    
    private func download(source: Engine.Source, _ completion: @escaping DownloadCompletion) {
        
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
