import Foundation

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
        let errorPatterns = [
            #"^(.+):(\d+):(\d+): error: (.+)$"#,
            #"^(.+):(\d+): error: (.+)$"#,
            #"^(.+): error: (.+)$"#,
            #"^(.+):(\d+): Fatal error: (.+)$"#,
            #"^(.+): Fatal error: (.+)$"#,
            #"^❌ (.+)$"#,
            #"^error: (.+)$"#
        ]
        
        for pattern in errorPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
                if let match = matches.first {
                    let groups = (0..<match.numberOfRanges).map { i in
                        let range = match.range(at: i)
                        return range.location != NSNotFound ? String(line[Range(range, in: line)!]) : nil
                    }
                    
                    if groups.count >= 5 {
                        let file = groups[1]
                        let line = Int(groups[2] ?? "")
                        let message = groups[4] ?? ""
                        return BuildError(file: file, line: line, message: message)
                    } else if groups.count >= 4 {
                        let file = groups[1]
                        let line = Int(groups[2] ?? "")
                        let message = groups[3] ?? ""
                        return BuildError(file: file, line: line, message: message)
                    } else if groups.count >= 3 {
                        let file = groups[1]
                        let message = groups[2] ?? ""
                        return BuildError(file: file, line: nil, message: message)
                    } else if groups.count >= 2 {
                        return BuildError(file: nil, line: nil, message: groups[1] ?? "")
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseWarning(_ line: String) -> BuildWarning? {
        let warningPatterns = [
            #"^(.+):(\d+):(\d+): warning: (.+)$"#,
            #"^(.+):(\d+): warning: (.+)$"#,
            #"^(.+): warning: (.+)$"#,
            #"^⚠️ (.+)$"#,
            #"^warning: (.+)$"#
        ]
        
        for pattern in warningPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
                if let match = matches.first {
                    let groups = (0..<match.numberOfRanges).map { i in
                        let range = match.range(at: i)
                        return range.location != NSNotFound ? String(line[Range(range, in: line)!]) : nil
                    }
                    
                    if groups.count >= 5 {
                        let file = groups[1]
                        let line = Int(groups[2] ?? "")
                        let message = groups[4] ?? ""
                        return BuildWarning(file: file, line: line, message: message)
                    } else if groups.count >= 4 {
                        let file = groups[1]
                        let line = Int(groups[2] ?? "")
                        let message = groups[3] ?? ""
                        return BuildWarning(file: file, line: line, message: message)
                    } else if groups.count >= 3 {
                        let file = groups[1]
                        let message = groups[2] ?? ""
                        return BuildWarning(file: file, line: nil, message: message)
                    } else if groups.count >= 2 {
                        return BuildWarning(file: nil, line: nil, message: groups[1] ?? "")
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseFailedTest(_ line: String) -> FailedTest? {
        // Handle XCUnit test failures specifically first
        if line.contains("XCTAssertEqual failed") || line.contains("XCTAssertTrue failed") || line.contains("XCTAssertFalse failed") {
            // Look for the pattern: file:line: error: -[ClassName testMethod] : XCTAssert... failed: details
            if let testRegex = try? NSRegularExpression(pattern: #"^(.+):(\d+): error: -\[(.+?)\] : (.+)$"#, options: [.dotMatchesLineSeparators]) {
                let testMatches = testRegex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
                if let testMatch = testMatches.first, testMatch.numberOfRanges >= 5 {
                    let fileRange = testMatch.range(at: 1)
                    let lineRange = testMatch.range(at: 2)
                    let testNameRange = testMatch.range(at: 3)
                    let messageRange = testMatch.range(at: 4)
                    
                    let file = String(line[Range(fileRange, in: line)!])
                    let lineNumber = Int(String(line[Range(lineRange, in: line)!]))
                    let testName = String(line[Range(testNameRange, in: line)!])
                    let message = String(line[Range(messageRange, in: line)!])
                    return FailedTest(test: testName, message: message, file: file, line: lineNumber)
                }
            }
            // Fallback: extract whatever we can
            if let testRegex = try? NSRegularExpression(pattern: #"-\[(.+?)\]"#, options: []) {
                let testMatches = testRegex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
                if let testMatch = testMatches.first, testMatch.numberOfRanges >= 2 {
                    let testNameRange = testMatch.range(at: 1)
                    let testName = String(line[Range(testNameRange, in: line)!])
                    return FailedTest(test: testName, message: line.trimmingCharacters(in: .whitespaces), file: nil, line: nil)
                }
            }
            return FailedTest(test: "Test assertion", message: line.trimmingCharacters(in: .whitespaces), file: nil, line: nil)
        }
        
        let testPatterns = [
            #"^Test Case '(.+)' failed \((.+)\)$"#,
            #"^(.+): (.+) failed:(.+)$"#,
            #"^❌ (.+) \((.+)\)$"#,
            #"^(\S+) \((.+)\) failed$"#,
            #"^✘ Test "(.+)" recorded an issue at (.+):(\d+):\d+: (.+)$"#,
            #"^✘ Test "(.+)" failed after .+ with \d+ issues?.$"#
        ]
        
        for pattern in testPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
                if let match = matches.first {
                    let groups = (0..<match.numberOfRanges).map { i in
                        let range = match.range(at: i)
                        return range.location != NSNotFound ? String(line[Range(range, in: line)!]) : nil
                    }
                    
                    if groups.count >= 5 {
                        // Swift Testing pattern: ✘ Test "name" recorded an issue at file:line:column: message
                        let test = groups[1] ?? ""
                        let file = groups[2] ?? ""
                        let line = Int(groups[3] ?? "")
                        let message = groups[4] ?? ""
                        return FailedTest(test: test, message: message, file: file, line: line)
                    } else if groups.count >= 3 {
                        let test = groups[1] ?? ""
                        let message = groups[2] ?? ""
                        return FailedTest(test: test, message: message, file: nil, line: nil)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func parseBuildTime(_ line: String) -> String? {
        let timePatterns = [
            #"^Build succeeded in (.+)$"#,
            #"^Build failed after (.+)$"#,
            #"^Executed \d+ tests?, with \d+ failures? \(\d+ unexpected\) in (.+) \((.+)\) seconds$"#
        ]
        
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
                if let match = matches.first {
                    let groups = (0..<match.numberOfRanges).map { i in
                        let range = match.range(at: i)
                        return range.location != NSNotFound ? String(line[Range(range, in: line)!]) : nil
                    }
                    
                    if groups.count >= 2 {
                        return groups[1]
                    }
                }
            }
        }
        
        return nil
    }
}