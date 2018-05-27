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
