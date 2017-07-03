import Foundation

/**
 Generate fake for a `file` to `outFile`.
 
 - parameter file: The file to generate a fake for.
 - parameter outFile: The location to write the fake.
 - parameter module: The module which the class resides in.
 - parameter imports: A list of additional imports to include in the generated fake.
 */
internal func generateFake(file: String, outFile: String, module: String?, imports: [String]?) throws {
    var code = ""

    // CLI command that can be used to regenerate the fake.
    code = "// Copy and paste the following command to regenerate this fake\n" +
        "// bluffalo -file \(file) -outputFile \(outFile) \(moduleParameter(module))\n\n"
    
    // Additional imports
    code += additionalImports(from: imports)
    
    // Testable module import
    code += testableImport(module)

    // Generate source code.
    code += createFakeClassForFile(filepath: file) + "\n"

    write(code: code, to: outFile)
}

/**
 Load a Swift file using SourceKitten.
 
 - parameter filepath: The filepath to parse through SourceKitten
 - returns: A `SwiftFile` which contains the file's contents and JSON parsed through SourceKitten
 */
internal func loadSwiftFile(at filepath: String) -> SwiftFile {
    let sourceKittenPath: String = "/usr/local/bin/sourcekitten"
    
    guard FileManager.default.fileExists(atPath: sourceKittenPath) else {
        print("Error! SourceKitten does not exist at path: \(sourceKittenPath)")
        print("Install SourceKitten with 'brew install sourcekitten'")
        exit(1)
    }
    
    let contentsOfFile = try! String(contentsOfFile: filepath)
    
    let task = Process()
    task.launchPath = "/usr/local/bin/sourcekitten"
    task.arguments = ["structure", "--file", filepath]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let read: FileHandle = pipe.fileHandleForReading
    let dataRead: Data = read.readDataToEndOfFile()
    
    guard let json = try? JSONSerialization.jsonObject(with: dataRead, options: .allowFragments) as! [String:AnyObject] else {
        print("Error! Could not parse JSON data from sourcekitten.")
        exit(1)
    }
    
    return SwiftFile(contents: contentsOfFile, json: json)
}

/**
 Create a fake for the file at `filepath`.
 
 - parameter filepath: The filepath to create a fake for.
 - returns: The fake generated code as a string.
 */
internal func createFakeClassForFile(filepath: String) -> String {
    let file = loadSwiftFile(at: filepath)
    
    let classes: [ClassStruct] = parse(file: file)
    
    let code = classes.reduce("") { (code, classStruct) -> String in
        let generator = FakeClassGenerator()
        return code + generator.makeFakeClass(classStruct: classStruct) + "\n"
    }
    
    return code
}

// TODO: This should throw. Not just print.
internal func write(code: String, to filepath: String) {
    do {
        // TODO: Make `filepath` point to `Fakes.swift` if `filepath` not provided.
        let fileURL = URL(fileURLWithPath: filepath)
        try code.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
        print("Add \(fileURL.absoluteURL) to your project")
    }
    catch {
        print("Failed to write file")
    }
}

// MARK - Private functions

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
    
    return "@testable import \(module)\n\n"
}

/**
 Returns a list of all additional imports that need to be included in the source. This is provided by the `imports` parameter.
 */
private func additionalImports(from imports: [String]?) -> String {
    guard let imports = imports else {
        return ""
    }
    
    let code: String = imports.reduce("") { (code: String, importName: String) -> String in
        code + "import \(importName)\n"
    }
    return code + "\n"
}
