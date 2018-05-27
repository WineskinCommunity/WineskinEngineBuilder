//
//  EngineBuilder.swift
//  EngineBuilder
//
//  Created by Chris Ballinger on 5/27/18.
//

import Foundation

public enum EngineBuilderError: Error {
    case noEngineList
    case badEngineList
    case engineNotFound
    case buildError
}

public final class EngineBuilder {
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
    
    public func buildEngine(engineName: String, outputDirectory: String = "") throws {
        print("Building engine \(engineName)...")
        throw EngineBuilderError.engineNotFound
    }
    
    public func printAvailableEngines() {
        print("Available engines:")
        engineList.engines.forEach { print($0) }
    }
    
    public func printInstalledEngines() {
        print("Installed engines:")
        
    }
}
