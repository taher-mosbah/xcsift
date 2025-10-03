import ArgumentParser
import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

func getVersion() -> String {
    // Try to get version from git tag during build
    #if DEBUG
    return "dev"
    #else
    return "VERSION_PLACEHOLDER" // This will be replaced by build script
    #endif
}

struct XCSift: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcsift",
        abstract: "A Swift tool to parse and format xcodebuild output for coding agents",
        usage: "xcodebuild [options] | xcsift",
        discussion: """
        xcsift reads xcodebuild output from stdin and outputs structured JSON.
        
        Examples:
          xcodebuild build | xcsift
          xcodebuild test | xcsift
          swift build | xcsift
          swift test | xcsift
        """,
        helpNames: [.short, .long]
    )
    
    @Flag(name: [.short, .long], help: "Show version information")
    var version: Bool = false
    
    func run() throws {
        if version {
            print(getVersion())
            return
        }
        
        // Check if stdin is a terminal (no piped input) before trying to read
        if isatty(STDIN_FILENO) == 1 {
            throw ValidationError("No input provided. Please pipe xcodebuild output to xcsift.\n\nExample: xcodebuild build | xcsift")
        }
        
        let parser = OutputParser()
        
        // Check if we have any input (peek at the first line)
        var hasInput = false
        var firstLine: String?
        
        // We need to check if there's input, so collect at least one line
        if let line = readLine() {
            hasInput = true
            firstLine = line
        }
        
        if !hasInput {
            throw ValidationError("No input provided. Please pipe xcodebuild output to xcsift.\n\nExample: xcodebuild build | xcsift")
        }
        
        // Create a new sequence that includes the first line we already read
        let fullSequence = AnySequence { () -> AnyIterator<String> in
            var emittedFirst = false
            return AnyIterator {
                if !emittedFirst {
                    emittedFirst = true
                    return firstLine
                }
                return readLine()
            }
        }
        
        let result = parser.parse(lines: fullSequence)
        outputResult(result)
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
