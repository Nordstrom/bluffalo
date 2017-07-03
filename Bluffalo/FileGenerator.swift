import Foundation

struct Constant {
    static let tab: String = "    "
    static let newLine: String = "\n"
    static let equalityFunction = "checkEquality"
}

var contentsOfFile: String?

class FileGenerator {
    
    /**
     Generate fake for a `file` to `outFile`.
     
     - parameter file: The file to generate a fake for.
     - parameter outFile: The location to write the fake.
     - parameter module: The module which the class resides in.
     - parameter imports: A list of additional imports to include in the generated fake.
     */
    func generate(file: String, outFile: String, module: String?, imports: [String]?) throws {
        var code = ""

        // CLI command that can be used to regenerate the fake.
        code = "// Copy and paste the following command to regenerate this fake\(Constant.newLine)" +
            "// bluffalo -file \(file) -outputFile \(outFile) \(moduleParameter(module))\(Constant.newLine)\(Constant.newLine)"
        
        // Additional imports
        code += additionalImports(from: imports)
        
        // Testable module import
        code += testableImport(module)

        // Generate source code.
        code += createFakeClassForFile(filePath: file) + Constant.newLine
    
        write(code: code, to: outFile)
    }
    
    /**
     Returns the `-module` parameter if module is provided.
     */
    private func moduleParameter(_ module: String?) -> String {
        // TODO: Refactor this guard logic into a computed property (?)
        guard let module = module, module.characters.count > 0 else {
            return ""
        }

        return "-module \(module)"
    }
    
    /**
     Returns all testable imports.
     */
    private func testableImport(_ module: String?) -> String {
        guard let module = module else {
            return ""
        }
        
        return "@testable import \(module)\(Constant.newLine)\(Constant.newLine)"
    }
    
    /**
     Returns a list of all additional imports that need to be included in the source. This is provided by the `imports` parameter.
     */
    private func additionalImports(from imports: [String]?) -> String {
        guard let imports = imports else {
            return ""
        }
        
        let code: String = imports.reduce("") { (code: String, importName: String) -> String in
            code + "import \(importName)\(Constant.newLine)"
        }
        return code + Constant.newLine
    }
}
