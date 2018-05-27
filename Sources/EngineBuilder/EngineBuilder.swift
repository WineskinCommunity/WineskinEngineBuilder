//
//  EngineBuilder.swift
//  EngineBuilder
//
//  Created by Chris Ballinger on 5/27/18.
//

import Foundation
import AppFolder

public enum EngineBuilderError: Error {
    case noEngineList
    case badEngineList
    case engineNotFound
    case buildError
}

public final class EngineBuilder {
    public typealias BuildCompletion = (Engine?, Error?)->Void
    private let engineList: EngineList
    
    public convenience init(engineListPath: String) throws {
        let fileURL = URL(fileURLWithPath: engineListPath)
        let engineListData = try Data(contentsOf: fileURL)
        try self.init(engineListData: engineListData)
    }
    
    public init(engineListData: Data) throws {
        let decoder = JSONDecoder()
        self.engineList = try decoder.decode(EngineList.self, from: engineListData)
    }
    
    public func buildEngine(engineName: String, outputDirectory: String = "", completion: @escaping BuildCompletion) {
        print("Building engine \(engineName)...")
        let matches = engineList.engines.filter { $0.name == engineName }
        guard let match = matches.first else {
            completion(nil, EngineBuilderError.engineNotFound)
            return
        }
        guard let sourceBinary = match.binary() else {
            completion(nil, EngineBuilderError.engineNotFound)
            return
        }
        
        let engineCache = AppFolder.Library.Caches.WineskinEngineCache
        let engineCacheURL = engineCache.url
        do {
            try FileManager.default.createDirectory(at: engineCacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            completion(nil, error)
            return
        }
        let fileName = sourceBinary.url.lastPathComponent
        let destination = engineCacheURL.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: destination.path) {
            print("Found cached download at \(destination)")
            completion(match, nil)
            return
        }
        
        print("Downloading binary at \(sourceBinary.url) to \(destination)")
        let downloadTask = URLSession.shared.downloadTask(with: sourceBinary.url) { (url, response, error) in
            guard let url = url else {
                print("Could not download file: \(String(describing: error))")
                completion(nil, EngineBuilderError.buildError)
                return
            }
            do {
                try FileManager.default.moveItem(at: url, to: destination)
            } catch {
                print("Could not move engine binary from \(url) to \(destination)")
                completion(nil, EngineBuilderError.buildError)
                return
            }
            print("Download successful to \(destination)")

            completion(match, nil)
        }
        downloadTask.resume()
    }
    
    public func printAvailableEngines() {
        print("Available engines:")
        engineList.engines.forEach { print($0) }
    }
    
    public func printInstalledEngines() {
        print("Installed engines:")
        
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
