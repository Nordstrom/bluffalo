import XCTest

@testable import Bluffalo

class BluffaloTests: XCTestCase {
    
    func filePath(name: String) -> String {
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
    
    func classStructForFile(_ fileName: String) -> [ClassStruct] {
        let json = getJSONForFilePath(filepath: filePath(name: fileName))
        let classDictionaryArray = getClassDictionaries(json: json)
        
        var classStructureArray: [ClassStruct] = []
        for  dictionary in classDictionaryArray {
            let classStructure = Parser(json: dictionary).parse()
            classStructureArray.append(classStructure)
        }
        
        return classStructureArray
    }
    
    func testGenericGenerateClass() {
        let classStructArray: [ClassStruct] = classStructForFile("Cat")
        var finalClassString = ""
        for classStruct in classStructArray {
            let classString = FakeClassGenerator(classStruct: classStruct).makeFakeClass()
            finalClassString += classString + Constant.newLine
        }
        
        let expectedClassString = stringForFile(filePath(name: "FakeCat"))
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
