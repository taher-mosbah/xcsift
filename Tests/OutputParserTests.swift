import XCTest
@testable import xcsift

final class OutputParserTests: XCTestCase {
    
    func testParseError() {
        let parser = OutputParser()
        let input = """
        main.swift:15:5: error: use of undeclared identifier 'unknown'
        unknown = 5
        ^
        """
        
        let result = parser.parse(input: input)
        
        XCTAssertEqual(result.status, "failed")
        XCTAssertEqual(result.summary.errors, 1)
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertEqual(result.errors[0].file, "main.swift")
        XCTAssertEqual(result.errors[0].line, 15)
        XCTAssertEqual(result.errors[0].message, "use of undeclared identifier 'unknown'")
    }
    
    
    func testParseSuccessfulBuild() {
        let parser = OutputParser()
        let input = """
        Building for debugging...
        Build complete!
        """
        
        let result = parser.parse(input: input)
        
        XCTAssertEqual(result.status, "success")
        XCTAssertEqual(result.summary.errors, 0)
        XCTAssertEqual(result.summary.failedTests, 0)
    }
    
    func testFailingTest() {
        let parser = OutputParser()
        let input = """
        Test Case 'LoginTests.testInvalidCredentials' failed (0.045 seconds).
        XCTAssertEqual failed: Expected valid login
        """
        
        let result = parser.parse(input: input)
        
        XCTAssertEqual(result.status, "failed")
        XCTAssertEqual(result.summary.failedTests, 2)
        XCTAssertEqual(result.failedTests.count, 2)
        XCTAssertEqual(result.failedTests[0].test, "LoginTests.testInvalidCredentials")
        XCTAssertEqual(result.failedTests[1].test, "Test assertion")
    }
    
    func testMultipleErrors() {
        let parser = OutputParser()
        let input = """
        UserService.swift:45:12: error: cannot find 'invalidFunction' in scope
        NetworkManager.swift:23:5: error: use of undeclared identifier 'unknownVariable'
        AppDelegate.swift:67:8: warning: unused variable 'config'
        """
        
        let result = parser.parse(input: input)
        
        XCTAssertEqual(result.status, "failed")
        XCTAssertEqual(result.summary.errors, 2)
        XCTAssertEqual(result.errors.count, 2)
    }
    
    func testInvalidAssertion() {
        let line = "XCTAssertTrue failed - Connection should be established"
        let parser = OutputParser()
        let result = parser.parse(input: line)
        
        XCTAssertEqual(result.status, "failed")
        XCTAssertEqual(result.summary.failedTests, 1)
        XCTAssertEqual(result.failedTests.count, 1)
        XCTAssertEqual(result.failedTests[0].test, "Test assertion")
        XCTAssertEqual(result.failedTests[0].message, line.trimmingCharacters(in: .whitespaces))
    }
    
    func testWrongFileReference() {
        let parser = OutputParser()
        let input = """
        NonexistentFile.swift:999:1: error: file not found
        """
        
        let result = parser.parse(input: input)
        
        XCTAssertEqual(result.status, "failed")
        XCTAssertEqual(result.summary.errors, 1)
        XCTAssertEqual(result.errors[0].file, "NonexistentFile.swift")
        XCTAssertEqual(result.errors[0].line, 999)
        XCTAssertEqual(result.errors[0].message, "file not found")
    }
    
    func testBuildTimeExtraction() {
        let parser = OutputParser()
        let input = """
        Building for debugging...
        Build failed after 5.7 seconds
        """
        
        let result = parser.parse(input: input)
        
        XCTAssertEqual(result.summary.buildTime, "5.7 seconds")
    }
    
    func testDeprecatedFunction() {
        let parser = OutputParser()
        let _ = parser.deprecatedFunction()
        parser.functionWithUnusedVariable()
    }
    
    func testFirstFailingTest() {
        XCTAssertEqual("expected", "actual", "This test should fail - values don't match")
    }
    
    func testSecondFailingTest() {
        XCTAssertTrue(false, "This test should fail - asserting false")
    }
    
    func testParseCompileError() {
        let parser = OutputParser()
        let input = """
        UserManager.swift:42:10: error: cannot find 'undefinedVariable' in scope
        print(undefinedVariable)
        ^
        """
        
        let result = parser.parse(input: input)
        
        XCTAssertEqual(result.status, "failed")
        XCTAssertEqual(result.summary.errors, 1)
        XCTAssertEqual(result.errors[0].file, "UserManager.swift")
        XCTAssertEqual(result.errors[0].line, 42)
        XCTAssertEqual(result.errors[0].message, "cannot find 'undefinedVariable' in scope")
    }
    
    func testStreamingParse() {
        // Test that the new streaming parse method works correctly
        let parser = OutputParser()
        let lines = [
            "main.swift:15:5: error: use of undeclared identifier 'unknown'",
            "unknown = 5",
            "^",
            "Build failed after 3.2 seconds"
        ]
        
        let result = parser.parse(lines: lines)
        
        XCTAssertEqual(result.status, "failed")
        XCTAssertEqual(result.summary.errors, 1)
        XCTAssertEqual(result.errors[0].file, "main.swift")
        XCTAssertEqual(result.errors[0].line, 15)
        XCTAssertEqual(result.errors[0].message, "use of undeclared identifier 'unknown'")
        XCTAssertEqual(result.summary.buildTime, "3.2 seconds")
    }
    
    func testStreamingWithLargeInput() {
        // Test that streaming works efficiently with large inputs
        let parser = OutputParser()
        
        // Create a large sequence of lines (simulating a 20K line build log)
        let lineCount = 20000
        var lines: [String] = []
        
        // Add some normal build output
        lines.append("Building for debugging...")
        
        // Add many lines of normal output
        for i in 0..<lineCount {
            lines.append("Compiling SomeFile\(i).swift")
        }
        
        // Add some errors
        lines.append("Error.swift:100:5: error: something went wrong")
        lines.append("AnotherError.swift:200:10: error: another problem")
        
        // Add build time
        lines.append("Build failed after 120.5 seconds")
        
        // Parse using the streaming method
        let result = parser.parse(lines: lines)
        
        XCTAssertEqual(result.status, "failed")
        XCTAssertEqual(result.summary.errors, 2)
        XCTAssertEqual(result.errors.count, 2)
        XCTAssertEqual(result.errors[0].file, "Error.swift")
        XCTAssertEqual(result.errors[0].line, 100)
        XCTAssertEqual(result.errors[1].file, "AnotherError.swift")
        XCTAssertEqual(result.errors[1].line, 200)
        XCTAssertEqual(result.summary.buildTime, "120.5 seconds")
    }
    
    func testStreamingWithLazySequence() {
        // Test that streaming works with lazy sequences (true streaming without materializing all lines)
        let parser = OutputParser()
        
        // Create a lazy sequence that generates lines on-the-fly
        let lineCount = 10000
        let lazyLines = (0..<lineCount).lazy.map { i -> String in
            if i == 0 {
                return "Building for debugging..."
            } else if i == lineCount - 3 {
                return "Error.swift:50:5: error: streaming error"
            } else if i == lineCount - 2 {
                return "Test Case 'MyTest' failed (0.1 seconds)."
            } else if i == lineCount - 1 {
                return "Build failed after 60.0 seconds"
            } else {
                return "Compiling file\(i).swift"
            }
        }
        
        // Parse using the streaming method with a lazy sequence
        let result = parser.parse(lines: lazyLines)
        
        XCTAssertEqual(result.status, "failed")
        XCTAssertEqual(result.summary.errors, 1)
        XCTAssertEqual(result.summary.failedTests, 1)
        XCTAssertEqual(result.errors[0].file, "Error.swift")
        XCTAssertEqual(result.errors[0].line, 50)
        XCTAssertEqual(result.failedTests[0].test, "MyTest")
        XCTAssertEqual(result.summary.buildTime, "60.0 seconds")
    }
}