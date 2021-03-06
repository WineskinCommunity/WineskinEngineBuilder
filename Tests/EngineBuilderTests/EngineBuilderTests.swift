import XCTest
@testable import EngineBuilder

class EngineBuilderTests: XCTestCase {
    
    static let exampleEngineJsonString = """
    {
        "metadata":
        {
            "version": "0.0.1"
        },
        "engines":
        [
            {
                "name": "WS9Wine3.0.1",
                "description": "Wine Stable 3.0.1",
                "author": "WineHQ Official",
                "homepage": "https://dl.winehq.org/wine-builds/macosx/download.html",
                "sources":
                [
                    {
                        "url": "https://dl.winehq.org/wine-builds/macosx/pool/portable-winehq-stable-3.0.1-osx64.tar.gz",
                        "sha256": "07429ae28be5ad811027ed15a9b58a6bbc5fb55a3cd2c4c803ed72d5c67a59aa",
                        "arch": ["32", "64"],
                        "type": "portable-winehq"
                    },
                    {
                        "url": "https://dl.winehq.org/wine-builds/macosx/pool/portable-winehq-stable-3.0.1-osx.tar.gz",
                        "sha256": "cc74c62868db89305a7bae02d72d053ff02f839e205657a62d8fc1a661198a20",
                        "arch": ["32"],
                        "type": "portable-winehq"
                    },
                    {
                        "url": "https://dl.winehq.org/wine/source/3.0/wine-3.0.1.tar.xz",
                        "sha256": "bad00d7ddac6652795a2ed52ce02a544ff4e891499b29ac71d28d20b8e1d26f3",
                        "type": "source"
                    }
                ]
            }
        ]
    }
    """
    
    func testParsing() {
        let data = EngineBuilderTests.exampleEngineJsonString.data(using: .utf8)!
        let engineBuilder = try! EngineManager(engineListData: data)
        engineBuilder.engines.forEach {
            print($0.consoleDescription)
        }
        XCTAssert(engineBuilder.engines.count > 0)
    }
    
    func testBuildEngine() {
        /// TODO: make this test not fail if file already exists
        let data = EngineBuilderTests.exampleEngineJsonString.data(using: .utf8)!
        let engineBuilder = try! EngineManager(engineListData: data)
        let expectation = self.expectation(description: "Build")
        engineBuilder.buildEngine(engineName: "WS9Wine3.0.1", outputDirectory: "", p7zip: URL(fileURLWithPath: "/usr/local/bin/7za")) { (result) in
            switch result {
            case .success(let engine):
                print("Engine built successfully.\n")
                print(engine.consoleDescription)
                try? FileManager.default.removeItem(at: engine.url)
            case .failure(let error):
                XCTFail("Could not build engine \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 300) { (error) in
            if let error = error {
                print("Test timeout: \(String(describing: error))")
            }
        }
    }
}
