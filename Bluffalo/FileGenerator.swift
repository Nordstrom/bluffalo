import Foundation

// Next up: split out the app-wrapper from file generation. 
// Make a parameterized WriteOneFake() method.
// Add support for new fake:source sytax in list file

let tab: String = "    "
let newLine: String = "\n"
let equalityFunction = "checkEquality"

var contentsOfFile: String?

class FileGenerator {
    var listOfFilesFile = ""
    var outputDirectory = ""
    var testableModule = ""
    var file = ""
    var outputFile = ""
    var listOfImports = ""

    func generate() -> Int {
        var fakeClasses = ""

        // Generate command line comment
        fakeClasses += "// Copy and paste the following command to regenerate this fake \n"
        fakeClasses += "// bluffalo -file \(file) -outputFile \(outputFile) -module \(testableModule) \n\n"
        
        let imports = getImportsForFile(path: file)
        for importString in imports {
            fakeClasses += importString + "\n"
        }
        fakeClasses += "\n"
        
        // Additional imports
        if listOfImports.characters.count > 0 {
            let importNames:[String] = listOfImports.components(separatedBy: ",")
            importNames.forEach({ (importName: String) in
                fakeClasses += "import \(importName)\(newLine)"
            })
            
            fakeClasses += newLine
        }

        //Testable module includes
        if testableModule.characters.count > 0 {
            fakeClasses += "@testable import \(testableModule)\(newLine)"
            fakeClasses += newLine
        }
        
        if listOfFilesFile.characters.count > 0 {
            var listOfFilePaths = ""
            do {
                listOfFilePaths = try String(contentsOfFile: listOfFilesFile, encoding: .utf8)
            }
            catch {
                print("Error trying to get contents of file: \(listOfFilesFile)")
                exit(1)
            }
            
            let listOfPaths: [String] = listOfFilePaths.characters.split(separator: "\n").map(String.init)
            print("File Paths To Fake: \(listOfPaths)")
            
            for filePath: String in listOfPaths {
                fakeClasses += createFakeClassForFile(filePath: filePath) + newLine
            }
            
            writeStringToFile(stringToWrite: fakeClasses, outputDirectory: outputDirectory, outputFile:outputFile)
            
        }
        else {
            fakeClasses += createFakeClassForFile(filePath: file)
            
            writeStringToFile(stringToWrite: fakeClasses, outputDirectory: outputDirectory, outputFile: outputFile)
        }
        
        return 0
    }
}
