import ArgumentParser
import Foundation

struct XCSift: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcsift",
        abstract: "A Swift tool to parse and format xcodebuild output for coding agents",
        version: "1.0.0"
    )
    
    @Option(name: .shortAndLong, help: "Output format (json, compact)")
    var format: String = "json"
    
    @Flag(name: .shortAndLong, help: "Show only errors and failed tests")
    var quiet: Bool = false
    
    @Flag(name: .shortAndLong, help: "Show help message")
    var help: Bool = false
    
    func run() throws {
        let parser = OutputParser()
        let input = readStandardInput()
        let result = parser.parse(input: input)
        
        if quiet {
            let filteredResult = BuildResult(
                status: result.status,
                summary: result.summary,
                errors: result.errors,
                warnings: [],
                failedTests: result.failedTests
            )
            outputResult(filteredResult)
        } else {
            outputResult(result)
        }
    }
    
    private func readStandardInput() -> String {
        var input = ""
        while let line = readLine() {
            input += line + "\n"
        }
        return input
    }
    
    private func outputResult(_ result: BuildResult) {
        switch format.lowercased() {
        case "json":
            outputJSON(result)
        case "compact":
            outputCompact(result)
        default:
            outputJSON(result)
        }
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
    
    private func outputCompact(_ result: BuildResult) {
        print("STATUS: \(result.status)")
        print("SUMMARY: \(result.summary.errors)E \(result.summary.warnings)W \(result.summary.failedTests)F")
        
        if !result.errors.isEmpty {
            print("ERRORS:")
            for error in result.errors {
                if let file = error.file, let line = error.line {
                    print("  \(file):\(line) - \(error.message)")
                } else {
                    print("  \(error.message)")
                }
            }
        }
        
        if !result.warnings.isEmpty {
            print("WARNINGS:")
            for warning in result.warnings {
                if let file = warning.file, let line = warning.line {
                    print("  \(file):\(line) - \(warning.message)")
                } else {
                    print("  \(warning.message)")
                }
            }
        }
        
        if !result.failedTests.isEmpty {
            print("FAILED TESTS:")
            for test in result.failedTests {
                print("  \(test.test) - \(test.message)")
            }
        }
    }
}

XCSift.main()
