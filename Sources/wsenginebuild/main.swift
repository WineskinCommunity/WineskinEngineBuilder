import Commander
import EngineBuilder

command(
    Option("engines", default: "engines.json", description: "Path to engines.json"),
    Option("outDir", default: "", description: "Output directory for built engine. (Defaults to current working directory)"),
    Option("buildEngine", default: "", description: "Build specified engine e.g. WS9Wine3.0.1"),
    Flag("listEngines", default: false, description: "List available engines from engines.json"),
    Flag("installedEngines", default: false, description: "List engines installed in ~/Application Support/Wineskin")

) { (engines, outDir, buildEngine, listEngines, installedEngines) in
    do {
        let engineBuilder = try EngineBuilder(engineListPath: engines)
        if listEngines {
            engineBuilder.printAvailableEngines()
            return
        }
        if installedEngines {
            engineBuilder.printInstalledEngines()
            return
        }
        if buildEngine.count > 0 {
            try engineBuilder.buildEngine(engineName: buildEngine, outputDirectory: outDir)
        }
    } catch {
        print("Error: \(error)")
    }
}.run()