import Foundation
import RegexBuilder

struct BuildResult: Codable {
    let status: String
    let summary: BuildSummary
    let errors: [BuildError]
    let warnings: [BuildWarning]
    let failedTests: [FailedTest]
    
    enum CodingKeys: String, CodingKey {
        case status, summary, errors, warnings
        case failedTests = "failed_tests"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encode(summary, forKey: .summary)
        
        if !errors.isEmpty {
            try container.encode(errors, forKey: .errors)
        }
        
        if !warnings.isEmpty {
            try container.encode(warnings, forKey: .warnings)
        }
        
        if !failedTests.isEmpty {
            try container.encode(failedTests, forKey: .failedTests)
        }
    }
}

struct BuildSummary: Codable {
    let errors: Int
    let warnings: Int
    let failedTests: Int
    let buildTime: String?
    
    enum CodingKeys: String, CodingKey {
        case errors, warnings
        case failedTests = "failed_tests"
        case buildTime = "build_time"
    }
}

struct BuildError: Codable {
    let file: String?
    let line: Int?
    let message: String
}

struct BuildWarning: Codable {
    let file: String?
    let line: Int?
    let message: String
}

struct FailedTest: Codable {
    let test: String
    let message: String
    let file: String?
    let line: Int?
}

class OutputParser {
    private var errors: [BuildError] = []
    private var warnings: [BuildWarning] = []
    private var failedTests: [FailedTest] = []
    private var buildTime: String?
    
    @available(*, deprecated, message: "This function will be removed in a future version")
    func deprecatedFunction() -> String {
        return "This function is deprecated"
    }
    
    func functionWithUnusedVariable() {
        let unusedVariable = "This variable is never used and will cause a warning"
    }
    
    func parse(input: String) -> BuildResult {
        let lines = input.components(separatedBy: .newlines)
        
        for i in 0..<lines.count {
            parseLine(lines[i])
        }
        
        let status = errors.isEmpty && failedTests.isEmpty ? "success" : "failed"
        
        let summary = BuildSummary(
            errors: errors.count,
            warnings: warnings.count,
            failedTests: failedTests.count,
            buildTime: buildTime
        )
        
        return BuildResult(
            status: status,
            summary: summary,
            errors: errors,
            warnings: warnings,
            failedTests: failedTests
        )
    }
    
    private func parseLine(_ line: String) {
        if let failedTest = parseFailedTest(line) {
            failedTests.append(failedTest)
        } else if let error = parseError(line) {
            errors.append(error)
        } else if let warning = parseWarning(line) {
            warnings.append(warning)
        } else if let time = parseBuildTime(line) {
            buildTime = time
        }
    }
    
    private func parseError(_ line: String) -> BuildError? {
        // Pattern: file:line:column: error: message
        let fileLineColumnError = Regex {
            Capture(OneOrMore(.any, .reluctant))
            ":"
            Capture(OneOrMore(.digit))
            ":"
            OneOrMore(.digit)
            ": error: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: fileLineColumnError) {
            let file = String(match.1)
            let lineNumber = Int(String(match.2))
            let message = String(match.3)
            return BuildError(file: file, line: lineNumber, message: message)
        }
        
        // Pattern: file:line: error: message
        let fileLineError = Regex {
            Capture(OneOrMore(.any, .reluctant))
            ":"
            Capture(OneOrMore(.digit))
            ": error: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: fileLineError) {
            let file = String(match.1)
            let lineNumber = Int(String(match.2))
            let message = String(match.3)
            return BuildError(file: file, line: lineNumber, message: message)
        }
        
        // Pattern: file: error: message
        let fileError = Regex {
            Capture(OneOrMore(.any, .reluctant))
            ": error: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: fileError) {
            let file = String(match.1)
            let message = String(match.2)
            return BuildError(file: file, line: nil, message: message)
        }
        
        // Pattern: file:line: Fatal error: message
        let fileFatalError = Regex {
            Capture(OneOrMore(.any, .reluctant))
            ":"
            Capture(OneOrMore(.digit))
            ": Fatal error: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: fileFatalError) {
            let file = String(match.1)
            let lineNumber = Int(String(match.2))
            let message = String(match.3)
            return BuildError(file: file, line: lineNumber, message: message)
        }
        
        // Pattern: file: Fatal error: message
        let fatalError = Regex {
            Capture(OneOrMore(.any, .reluctant))
            ": Fatal error: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: fatalError) {
            let file = String(match.1)
            let message = String(match.2)
            return BuildError(file: file, line: nil, message: message)
        }
        
        // Pattern: ❌ message
        let emojiError = Regex {
            "❌ "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: emojiError) {
            let message = String(match.1)
            return BuildError(file: nil, line: nil, message: message)
        }
        
        // Pattern: error: message
        let simpleError = Regex {
            "error: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: simpleError) {
            let message = String(match.1)
            return BuildError(file: nil, line: nil, message: message)
        }
        
        return nil
    }
    
    private func parseWarning(_ line: String) -> BuildWarning? {
        // Pattern: file:line:column: warning: message
        let fileLineColumnWarning = Regex {
            Capture(OneOrMore(.any, .reluctant))
            ":"
            Capture(OneOrMore(.digit))
            ":"
            OneOrMore(.digit)
            ": warning: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: fileLineColumnWarning) {
            let file = String(match.1)
            let lineNumber = Int(String(match.2))
            let message = String(match.3)
            return BuildWarning(file: file, line: lineNumber, message: message)
        }
        
        // Pattern: file:line: warning: message
        let fileLineWarning = Regex {
            Capture(OneOrMore(.any, .reluctant))
            ":"
            Capture(OneOrMore(.digit))
            ": warning: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: fileLineWarning) {
            let file = String(match.1)
            let lineNumber = Int(String(match.2))
            let message = String(match.3)
            return BuildWarning(file: file, line: lineNumber, message: message)
        }
        
        // Pattern: file: warning: message
        let fileWarning = Regex {
            Capture(OneOrMore(.any, .reluctant))
            ": warning: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: fileWarning) {
            let file = String(match.1)
            let message = String(match.2)
            return BuildWarning(file: file, line: nil, message: message)
        }
        
        // Pattern: ⚠️ message
        let emojiWarning = Regex {
            "⚠️ "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: emojiWarning) {
            let message = String(match.1)
            return BuildWarning(file: nil, line: nil, message: message)
        }
        
        // Pattern: warning: message
        let simpleWarning = Regex {
            "warning: "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: simpleWarning) {
            let message = String(match.1)
            return BuildWarning(file: nil, line: nil, message: message)
        }
        
        return nil
    }
    
    private func parseFailedTest(_ line: String) -> FailedTest? {
        // Handle XCUnit test failures specifically first
        if line.contains("XCTAssertEqual failed") || line.contains("XCTAssertTrue failed") || line.contains("XCTAssertFalse failed") {
            // Pattern: file:line: error: -[ClassName testMethod] : XCTAssert... failed: details
            let xctestPattern = Regex {
                Capture(OneOrMore(.any, .reluctant))
                ":"
                Capture(OneOrMore(.digit))
                ": error: -["
                Capture(OneOrMore(.any, .reluctant))
                "] : "
                Capture(OneOrMore(.any, .reluctant))
                Anchor.endOfSubject
            }
            
            if let match = line.firstMatch(of: xctestPattern) {
                let file = String(match.1)
                let lineNumber = Int(String(match.2))
                let testName = String(match.3)
                let message = String(match.4)
                return FailedTest(test: testName, message: message, file: file, line: lineNumber)
            }
            
            // Fallback: extract test name from -[ClassName testMethod] format
            let testNamePattern = Regex {
                "-["
                Capture(OneOrMore(.any, .reluctant))
                "]"
            }
            
            if let match = line.firstMatch(of: testNamePattern) {
                let testName = String(match.1)
                return FailedTest(test: testName, message: line.trimmingCharacters(in: .whitespaces), file: nil, line: nil)
            }
            
            return FailedTest(test: "Test assertion", message: line.trimmingCharacters(in: .whitespaces), file: nil, line: nil)
        }
        
        // Pattern: Test Case 'TestName' failed (time)
        let testCasePattern = Regex {
            "Test Case '"
            Capture(OneOrMore(.any, .reluctant))
            "' failed ("
            Capture(OneOrMore(.any, .reluctant))
            ")"
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: testCasePattern) {
            let test = String(match.1)
            let message = String(match.2)
            return FailedTest(test: test, message: message, file: nil, line: nil)
        }
        
        // Pattern: ✘ Test "name" recorded an issue at file:line:column: message
        let swiftTestingIssuePattern = Regex {
            "✘ Test \""
            Capture(OneOrMore(.any, .reluctant))
            "\" recorded an issue at "
            Capture(OneOrMore(.any, .reluctant))
            ":"
            Capture(OneOrMore(.digit))
            ":"
            OneOrMore(.digit)
            ": "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: swiftTestingIssuePattern) {
            let test = String(match.1)
            let file = String(match.2)
            let lineNumber = Int(String(match.3))
            let message = String(match.4)
            return FailedTest(test: test, message: message, file: file, line: lineNumber)
        }
        
        // Pattern: ✘ Test "name" failed after time with N issues.
        let swiftTestingFailedPattern = Regex {
            "✘ Test \""
            Capture(OneOrMore(.any, .reluctant))
            "\" failed after "
            OneOrMore(.any, .reluctant)
            " with "
            OneOrMore(.digit)
            " issue"
            Optionally("s")
            "."
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: swiftTestingFailedPattern) {
            let test = String(match.1)
            return FailedTest(test: test, message: "Test failed", file: nil, line: nil)
        }
        
        // Pattern: ❌ testname (message)
        let emojiTestPattern = Regex {
            "❌ "
            Capture(OneOrMore(.any, .reluctant))
            " ("
            Capture(OneOrMore(.any, .reluctant))
            ")"
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: emojiTestPattern) {
            let test = String(match.1)
            let message = String(match.2)
            return FailedTest(test: test, message: message, file: nil, line: nil)
        }
        
        // Pattern: testname (message) failed
        let testFailedPattern = Regex {
            Capture(OneOrMore(.any, .reluctant))
            " ("
            Capture(OneOrMore(.any, .reluctant))
            ") failed"
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: testFailedPattern) {
            let test = String(match.1)
            let message = String(match.2)
            return FailedTest(test: test, message: message, file: nil, line: nil)
        }
        
        // Pattern: generic failed test with colon
        let colonFailedPattern = Regex {
            Capture(OneOrMore(.any, .reluctant))
            ": "
            Capture(OneOrMore(.any, .reluctant))
            " failed:"
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: colonFailedPattern) {
            let test = String(match.1)
            let message = String(match.2)
            return FailedTest(test: test, message: message, file: nil, line: nil)
        }
        
        return nil
    }
    
    private func parseBuildTime(_ line: String) -> String? {
        // Pattern: Build succeeded in time
        let buildSucceededPattern = Regex {
            "Build succeeded in "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: buildSucceededPattern) {
            return String(match.1)
        }
        
        // Pattern: Build failed after time
        let buildFailedPattern = Regex {
            "Build failed after "
            Capture(OneOrMore(.any, .reluctant))
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: buildFailedPattern) {
            return String(match.1)
        }
        
        // Pattern: Executed N tests, with N failures (N unexpected) in time (seconds) seconds
        let executedTestsPattern = Regex {
            "Executed "
            OneOrMore(.digit)
            " test"
            Optionally("s")
            ", with "
            OneOrMore(.digit)
            " failure"
            Optionally("s")
            " ("
            OneOrMore(.digit)
            " unexpected) in "
            Capture(OneOrMore(.any, .reluctant))
            " ("
            Capture(OneOrMore(.any, .reluctant))
            ") seconds"
            Anchor.endOfSubject
        }
        
        if let match = line.firstMatch(of: executedTestsPattern) {
            return String(match.1)
        }
        
        return nil
    }
}