//
//  ConsolePrintable.swift
//  EngineBuilder
//
//  Created by Chris Ballinger on 5/28/18.
//

import Foundation


public protocol ConsolePrintable {
    /// Printable to the command line console
    var consoleDescription: String { get }
}

extension EngineList: ConsolePrintable {
    public var consoleDescription: String {
        var desc = ""
        desc += "Engines: "
        engines.forEach {
            desc += "\t - \($0.name)\n"
        }
        //desc += "Last Updated: \()"
        return desc
    }
}

extension Engine: ConsolePrintable {
    public var consoleDescription: String {
        var desc = ""
        desc += "Name: \(name)\n"
        desc += "Description: \(description)\n"
        desc += "Author: \(author)\n"
        desc += "Homepage: \(homepage)\n"
        desc += "Sources:\n"
        sources.forEach {
            desc += " - \($0.url)\n"
            desc += "   SHA256: \($0.sha256)\n"
        }
        return desc
    }
}

extension ArchivedEngine: ConsolePrintable {
    public var consoleDescription: String {
        var desc = ""
        desc += "Name: \(name)\n"
        desc += " - \(url.path)\n"
        desc += "   SHA256: \(sha256)\n"
        return desc
    }
}
