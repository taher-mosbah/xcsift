# xcsift

A Swift command-line tool to parse and format xcodebuild/SPM output for coding agents, optimized for token efficiency.

## Overview

`xcsift` is designed to process verbose Xcode build output and transform it into a concise, structured format that coding agents can efficiently parse and act upon. Unlike `xcbeautify` and `xcpretty` which focus on human-readable output, `xcsift` prioritizes information density and machine readability.

## Features

- **Token-efficient JSON output** - Compact format optimized for coding agents
- **Structured error reporting** - Clear categorization of errors, warnings, and test failures
- **File/line number extraction** - Easy navigation to problematic code locations
- **Build status summary** - Quick overview of build results
- **Multiple output formats** - JSON (default) and compact text formats
- **Quiet mode** - Show only errors and failed tests

## Installation

### Option 1: Download Pre-built Binary (Recommended)

Download the latest release from [GitHub Releases](https://github.com/ldomaradzki/xcsift/releases):

```bash
# Download and extract
curl -L https://github.com/ldomaradzki/xcsift/releases/latest/download/xcsift-vX.X.X-macos-arm64.tar.gz | tar -xz

# Move to PATH
mv xcsift /usr/local/bin/xcsift
chmod +x /usr/local/bin/xcsift
```

### Option 2: Build from Source

```bash
git clone https://github.com/ldomaradzki/xcsift.git
cd xcsift
swift build -c release
cp .build/release/xcsift /usr/local/bin/
```

## Usage

Pipe xcodebuild output directly to xcsift:

```bash
xcodebuild [flags] | xcsift
```

### Options

- `--format json` - JSON output (default)
- `--format compact` - Compact text output
- `--quiet` - Show only errors and failed tests (hide warnings)

### Examples

```bash
# Basic usage with JSON output
xcodebuild build | xcsift

# Compact format for quick overview
xcodebuild test | xcsift --format compact

# Quiet mode - only show critical issues
xcodebuild build | xcsift --quiet
```

## Output Format

### JSON Format (default)

```json
{
  "status": "failed",
  "summary": {
    "errors": 2,
    "warnings": 1,
    "failed_tests": 2,
    "build_time": "3.2 seconds"
  },
  "errors": [
    {
      "file": "main.swift",
      "line": 15,
      "message": "use of undeclared identifier 'unknown'"
    }
  ],
  "warnings": [
    {
      "file": "ViewController.swift",
      "line": 23,
      "message": "variable 'temp' was never used; consider removing it"
    }
  ],
  "failed_tests": [
    {
      "test": "Test assertion",
      "message": "XCTAssertEqual failed: (\"invalid\") is not equal to (\"valid\")"
    }
  ]
}
```

### Compact Format

```
STATUS: failed
SUMMARY: 2E 1W 2F
ERRORS:
  main.swift:15 - use of undeclared identifier 'unknown'
WARNINGS:
  ViewController.swift:23 - variable 'temp' was never used; consider removing it
FAILED TESTS:
  Test assertion - XCTAssertEqual failed: ("invalid") is not equal to ("valid")
```

## Comparison with xcbeautify/xcpretty

| Feature | xcsift | xcbeautify | xcpretty |
|---------|---------|------------|----------|
| **Target audience** | Coding agents | Humans | Humans |
| **Output format** | JSON/compact | Colorized text | Formatted text |
| **Token efficiency** | High | Medium | Low |
| **Machine readable** | Yes | No | Limited |
| **Error extraction** | Structured | Visual | Visual |
| **Build time** | Fast | Fast | Slower |

## Development

### Running Tests

```bash
swift test
```

### Building

```bash
swift build
```

## License

MIT License