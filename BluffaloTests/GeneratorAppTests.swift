import XCTest

// Replace the global print() function with a test double so we can capture test-target print() calls
var printedLines: [String] = []
func print(_ item: String)
{
    printedLines.append(item)
}

// Compares two arrays of strings, returns the first difference between them, or nil if equal.
func diff(_ expected: [String], _ actual: [String]) -> String? {
    var expectedIterator = expected.makeIterator()
    var actualIterator = actual.makeIterator()
    while let expectedLine = expectedIterator.next() {
        if let actualLine = actualIterator.next() {
            if expectedLine != actualLine {
                return "expected: '\(expectedLine)'\nactual: '\(actualLine)'"
            }
        }
        else {
            return "actual ended prematurely at '\(expectedLine)'')'"
        }
    }

    if let actualLine = actualIterator.next() {
        return "actual contains extra lines: '\(actualLine)'"
    }
    
    return nil
}

class GeneratorAppTests: XCTestCase {
    
    var subject: GeneratorApp!

    override func setUp() {
        super.setUp()
        printedLines = []
        subject = GeneratorApp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testCanInstantiateAppClass() {
        XCTAssertNotNil(subject)
    }
    
    func testEmptyArgumentsArrayPrintsError() {
        let exitCode = subject.main(arguments: [])
        XCTAssertEqual(exitCode, 2)
        let expectedUsage = ["missing argument array"]
        let actualUsage = printedLines
        XCTAssertNil(diff(expectedUsage, actualUsage));
    }

    func testEmptyArgumentsListPrintsUsageHint() {
        let exitCode = subject.main(arguments: ["app-name"])
        XCTAssertEqual(exitCode, 1)
        let expectedUsage = ["Missing arguments. -? for help."]
        let actualUsage = printedLines
        XCTAssertNil(diff(expectedUsage, actualUsage));
    }

    func testUsageOptionPrintUsage() {
        let exitCode = subject.main(arguments: ["app-name", "-?"])
        XCTAssertEqual(exitCode, 1)
        let expectedUsage = [
            "bluffalo v1.0 - A cuddly little source kitten tool",
            "",
            "usage:",
            "",
            "    -list <file>            ",
            "    -outputDirectory <dir>  ",
            "    -module <module>        The module that your real class lives in.",
            "    -file <file>            Your input file.",
            "    -outputFile <file>      The output file.",
            "    -imports <names>        Any extra imports you want added to the file.",
            "    -help, -h, -?           "
        ]
        
        let actualUsage = printedLines
        XCTAssertNil(diff(expectedUsage, actualUsage));
    }

    
}
