import Foundation

public struct EngineList: Codable {
    public var engines: [Engine]
    public var metadata: Metadata
    
    public struct Metadata: Codable {
        public var version: String
    }
}

public struct Engine: Codable {
    public var name: String
    public var description: String
    public var author: String
    public var homepage: URL
    public var sources: [Source]
    
    public func binary(arch: [Source.Arch] = [.i386, .x86_64]) -> Source? {
        return sources.filter { $0.arch == arch }.first
    }
    
    public struct Source: Codable {
        public var url: URL
        public var sha256: String
        public var arch: [Arch]?
        public var type: SourceType
        public enum Arch: String, Codable {
            case i386 = "32"
            case x86_64 = "64"
        }
        public enum SourceType: String, Codable {
            case source
            case binaryWineHQ = "portable-winehq"
        }
    }
}

/// Represents packaged engine ready for installation
public struct ArchivedEngine {
    public var name: String
    public var url: URL
    public var sha256: String
    
    public init(url: URL, sha256: String? = nil) throws {
        self.url = url
        // normally path ends in .tar.7z
        self.name = url.deletingPathExtension().deletingPathExtension().lastPathComponent
        if let sha256 = sha256 {
            self.sha256 = sha256
        } else {
            let digest = try url.sha256Digest()
            self.sha256 = digest.toHexString()
        }
    }
}

