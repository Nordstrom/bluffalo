import XCTest

class BluffaloTests: XCTestCase {
    
    func resourceFilepath(for name: String) -> String {
        let filePath = Bundle(for: type(of: self)).path(forResource: name, ofType: "txt")!
        return filePath
    }
    
    func stringForFile(_ path: String) -> String {
        var fileContents = ""

        do {
            fileContents = try String(contentsOfFile: path, encoding: .utf8)
        }
        catch {
            print("Can't Find File")
        }
        
        return fileContents
    }
    
    func classStructForFile(_ fileName: String) -> [Class] {
        let filepath = resourceFilepath(for: fileName)
        let file = loadSwiftFile(at: filepath)
        let classes: [Class] = parse(file: file)
        
        return classes
    }
    
    func testGenericGenerateClass() {
        let classStructArray: [Class] = classStructForFile("Cat")
        var finalClassString = ""
        for classStruct in classStructArray {
            let classString = FakeClassGenerator(classStruct: classStruct).makeFakeClass()
            finalClassString += classString + "\n"
        }
        
        let filepath = resourceFilepath(for: "FakeCat")
        let expectedClassString = stringForFile(filepath)
        XCTAssertNil(compareClassStrings(actual: finalClassString, expected: expectedClassString))
    }
    
    func compareClassStrings(actual: String, expected: String) -> String? {
        let actualLines = actual.components(separatedBy: CharacterSet(charactersIn: "\n"))
        let expectedLines = expected.components(separatedBy: CharacterSet(charactersIn: "\n"))
        let lineCount = min(actualLines.count, expectedLines.count)
        for index in 0 ..< lineCount {
            let actual = actualLines[index]
            let expected = expectedLines[index]
            if actual != expected {
                return "expected: \"\(expected)\"\n" +
                       "actual: \"\(actual)\"\n"
            }
        }
        
        return nil
    }
}
