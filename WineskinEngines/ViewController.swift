//
//  ViewController.swift
//  WineskinEngines
//
//  Created by Chris Ballinger on 5/29/18.
//

import Cocoa
import EngineBuilder

class ViewController: NSViewController {
    
    var engineManager: EngineManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupEngineManager()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    private func setupEngineManager() {
        guard let engines = Bundle.main.url(forResource: "engines", withExtension: "json") else {
            print("engines.json could not be found!")
            return
        }
        do {
            let engineManager = try EngineManager(engineListPath: engines.path)
            self.engineManager = engineManager
            let available = engineManager.engines
            
            print("Available Engines:\n")
            available.forEach {
                print($0.consoleDescription)
            }
            
            let installed = try engineManager.installedEngines()
            print("Installed Engines:\n")
            installed.forEach {
                print($0.consoleDescription)
            }
        } catch {
            print("Error: \(error)")
            if let error = error as? EngineError,
                error == .cannotFindInstalledEngines {
                // show dialog for r/w access to ~/Library/Application Support/Wineskin/Engines
            }
        }
    }
}

