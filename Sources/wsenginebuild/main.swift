import Commander
import EngineBuilder
import Foundation

let engines = Option("engines", default: "engines.json", description: "Path to engines.json")

Group {
    $0.command("build",
               Argument<String>("name"),
               engines,
               Option("out", default: "", description: "Output directory for built engine. (Defaults to current working directory)"),
               Option("7za", default: "/usr/local/bin/7za", description: "Path to 7za binary (provided by p7zip)"),
               Flag("source", description: "Builds from source (not yet supported)"),
               description: "Builds specified engine"
               ) { name, engines, out, p7zip, source in
        do {
            let engineBuilder = try EngineManager(engineListPath: engines)
            var outDir = out
            if outDir.count == 0 {
                outDir = FileManager.default.currentDirectoryPath
            }
            engineBuilder.buildEngine(engineName: name, outputDirectory: outDir, { (result) in
                switch result {
                case .success(let engine, let url):
                    print("Engine \(engine.name) built at \(url)")
                    break
                case .failure(let error):
                    print("Error building \(name): \(error)")
                    break
                }
            })
        } catch {
            print("Error: \(error)")
        }
    }
    
    $0.command("info",
               Argument<String>("name"),
               engines,
               description: "Prints info about engine"
    ) { name, engines in
        do {
            let engineBuilder = try EngineManager(engineListPath: engines)
            guard let engine = engineBuilder.engineForName(name) else {
                print("Error: engine \(name) not found")
                return
            }
            print(engine.consoleDescription)
        } catch {
            print("Error: \(error)")
        }
    }
    
    $0.command("list",
               Flag("installed", description: "Prints engines installed in ~/Application Support/Wineskin"),
               engines,
               description: "Prints available engines"
    ) { installed, engines in
        do {
            let engineBuilder = try EngineManager(engineListPath: engines)
            if installed {
                print("Installed Engines:\n")
                // TODO
            } else {
                print("Available Engines:\n")
                engineBuilder.engines.forEach {
                    print($0.consoleDescription)
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
}.run()
