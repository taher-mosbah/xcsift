import ArgumentParser
import Foundation

struct XCSift: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcsift",
        abstract: "A Swift tool to parse and format xcodebuild output for coding agents",
        version: "1.0.0"
    )
    
    
    
    
    func run() throws {
        let parser = OutputParser()
        let input = readStandardInput()
        let result = parser.parse(input: input)
        
        outputResult(result)
    }
    
    private func readStandardInput() -> String {
        var input = ""
        while let line = readLine() {
            input += line + "\n"
        }
        return input
    }
    
    private func outputResult(_ result: BuildResult) {
        outputJSON(result)
    }
    
    private func outputJSON(_ result: BuildResult) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if #available(macOS 10.15, *) {
            encoder.outputFormatting.insert(.withoutEscapingSlashes)
        }
        
        do {
            let jsonData = try encoder.encode(result)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            print("Error encoding JSON: \(error)")
        }
    }
    
}

XCSift.main()
