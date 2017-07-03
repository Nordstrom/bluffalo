import Foundation

// Next up: split out the app-wrapper from file generation. 
// Make a parameterized WriteOneFake() method.
// Add support for new fake:source sytax in list file

struct BluffaloError: Error {
    let description: String
}

struct Constant {
    static let tab: String = "    "
    static let newLine: String = "\n"
    static let equalityFunction = "checkEquality"
}

var contentsOfFile: String?

class FileGenerator {
    var listOfFilesFile: String?
    var outputDirectory = ""
    var testableModule: String?
    var file: String?
    var outputFile = ""
    var listOfImports = ""

    func generate() throws {
        var code = ""

        // Imports
        code += imports()
        
        // Additional imports
        code += additionalImports()
        
        // Testable module imports
        code += testableImports()
        
        // Generate source code
        var filePaths: [String]
        if let tmpFakeFiles = try? filesToFake(), let fakeFiles = tmpFakeFiles {
            filePaths = fakeFiles
            
            // TODO: Add command line comment at the top for multi-file gens.
        }
        else if let file = file {
            filePaths = [file]
            
            // Add CLI command at top of source file.
            code = "// Copy and paste the following command to regenerate this fake\(Constant.newLine)" +
                   "// bluffalo -file \(file) -outputFile \(outputFile) \(moduleParameter())\(Constant.newLine)\(Constant.newLine)" +
                   code
        }
        else {
            throw BluffaloError(description: "Either the `file` or `listOfFiles` parameter must be set with path to fake files.")
        }
        
        for filePath: String in filePaths {
            code += createFakeClassForFile(filePath: filePath) + Constant.newLine
        }
        
        writeStringToFile(stringToWrite: code, outputDirectory: outputDirectory, outputFile: outputFile)        
    }
    
    /**
     Returns a list of Swift file paths which should be faked.
     */
    private func filesToFake() throws -> [String]? {
        guard let filePath = listOfFilesFile, filePath.characters.count > 0 else {
            return nil
        }
        
        var listOfFilePaths = ""
        do {
            listOfFilePaths = try String(contentsOfFile: filePath, encoding: .utf8)
        }
        catch {
            throw BluffaloError(description: "Error trying to get contents of file: \(filePath)")
        }
        
        let listOfPaths: [String] = listOfFilePaths.characters.split(separator: "\n").map(String.init)
        
        return listOfPaths.flatMap({ (path) -> String? in
            path.trimmingCharacters(in: NSCharacterSet.whitespaces)
        })
    }
    
    /**
     Returns the `-module` parameter if module(s) were provided.
     */
    private func moduleParameter() -> String {
        // TODO: Refactor this guard logic into a computed property (?)
        guard let modules = testableModule, modules.characters.count > 0 else {
            return ""
        }

        return "-module \(modules)"
    }
    
    /**
     Returns all testable imports.
     */
    private func testableImports() -> String {
        guard let testModules = testableModule, testModules.characters.count > 0 else {
            return ""
        }
        
        let code: String = testModules.components(separatedBy: ",").reduce("") { (code: String, component: String) -> String in
            let module = component.trimmingCharacters(in: NSCharacterSet.whitespaces)
            return code + "@testable import \(module)\(Constant.newLine)"
        }
        
        return code + Constant.newLine
    }
    
    /**
     Returns all existing imports within the class file.
     */
    private func imports() -> String {
        guard let file = file else {
            return ""
        }
        
        let code: String = getImportsForFile(path: file).reduce("") { (code: String, importName: String) -> String in
            code + importName + Constant.newLine
        }
        return code + Constant.newLine
    }
    
    /**
     TODO: I'm not sure what this does or why it's needed.
     */
    private func additionalImports() -> String {
        guard listOfImports.characters.count > 0 else {
            return ""
        }
        
        let code: String = listOfImports.components(separatedBy: ",").reduce("") { (code: String, importName: String) -> String in
            code + "import \(importName)\(Constant.newLine)"
        }
        return code + Constant.newLine
    }
}
