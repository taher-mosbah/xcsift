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
    
    func testParseWarning() {
        let parser = OutputParser()
        let input = """
        ViewController.swift:23:9: warning: variable 'temp' was never used
        let temp = "test"
        ^
        """
        
        let result = parser.parse(input: input)
        
        XCTAssertEqual(result.status, "success")
        XCTAssertEqual(result.summary.warnings, 1)
        XCTAssertEqual(result.warnings.count, 1)
        XCTAssertEqual(result.warnings[0].file, "ViewController.swift")
        XCTAssertEqual(result.warnings[0].line, 23)
        XCTAssertEqual(result.warnings[0].message, "variable 'temp' was never used")
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
        XCTAssertEqual(result.summary.warnings, 0)
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
        XCTAssertEqual(result.summary.warnings, 1)
        XCTAssertEqual(result.errors.count, 2)
        XCTAssertEqual(result.warnings.count, 1)
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
}