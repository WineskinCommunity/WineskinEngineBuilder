//
//  EngineManager.swift
//  EngineBuilder
//
//  Created by Chris Ballinger on 5/27/18.
//

import Foundation
import AppFolder

public enum EngineError: Error {
    case noEngineList
    case badEngineList
    case engineNotFound
    case buildError
    case cannotFindInstalledEngines
}

public final class EngineManager {
    // MARK: - Private Properties
    
    private let engineList: EngineList
    
    // MARK: - Init
    
    public convenience init(engineListPath: String) throws {
        let fileURL = URL(fileURLWithPath: engineListPath)
        let engineListData = try Data(contentsOf: fileURL)
        try self.init(engineListData: engineListData)
    }
    
    public init(engineListData: Data) throws {
        let decoder = JSONDecoder()
        self.engineList = try decoder.decode(EngineList.self, from: engineListData)
    }
    
    // MARK: - Public Accessors
    
    public var engines: [Engine] {
        return engineList.engines
    }
    
    public func engineForName(_ name: String) -> Engine? {
        let matches = engines.filter { $0.name == name }
        if matches.count > 1 {
            print("Warning: More than one engine matching \(name): \(matches)")
        }
        return matches.first
    }
    
    public func installedEngines() throws -> [ArchivedEngine] {
        let wineskin = AppFolder.Library.Application_Support.Wineskin.url
        let enginesDir = wineskin.appendingPathComponent("Engines")
        guard FileManager.default.fileExists(atPath: enginesDir.path) else {
            throw EngineError.cannotFindInstalledEngines
        }
        let fileURLs = try FileManager.default.contentsOfDirectory(at: enginesDir, includingPropertiesForKeys: nil)
        
        var engines: [ArchivedEngine] = []
        fileURLs.forEach {
            guard $0.pathExtension == "7z" else {
                return
            }
            do {
                let engine = try ArchivedEngine(url: $0)
                engines.append(engine)
            } catch {
                print("Bad engine: \($0)")
            }
        }
        return engines
    }
    
    // MARK: - Public Methods
    
    public func buildEngine(engineName: String,
                            outputDirectory: String = "",
                            p7zip: URL,
                            _ completion: @escaping BuildCompletion) {
        print("Building engine \(engineName)...")
        let matches = engineList.engines.filter { $0.name == engineName }
        guard let engine = matches.first else {
            completion(.failure(EngineError.engineNotFound))
            return
        }
        let outURL = URL(fileURLWithPath: outputDirectory)
        do {
            let builder = try EngineBuilder(engine: engine, outputDirectory: outURL, p7zip: p7zip)
            builder.build(completion)
        } catch {
            completion(.failure(error))
            return
        }
    }
    
    // MARK: - Private Methods
}


extension Library.Application_Support {
    
    final class Wineskin : Directory { }
    
    var Wineskin: Wineskin {
        return subdirectory()
    }
    
}
