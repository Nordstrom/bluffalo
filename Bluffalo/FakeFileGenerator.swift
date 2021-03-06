/*
 * FakeFileGenerator.swift
 * Copyright (c) 2017 Nordstrom, Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/**
 Generate fake for a `file` to `outFile`.
 
 - parameter file: The file to generate a fake for.
 - parameter outFile: The location to write the fake.
 - parameter module: The module which the class resides in.
 - parameter imports: A list of additional imports to include in the generated fake.
 */
internal func generateFake(inFile: String, outFile: String, module: String?, imports: [String]?) throws {

    let file = try loadSwiftFile(at: inFile)
    let classes: [Class] = parse(file: file)

    let fakeUrl = URL(fileURLWithPath: outFile)
    
    try createFake(at: fakeUrl, inFile: inFile, outFile: outFile, classes: classes, module: module, imports: imports)
}

/**
 Load a Swift file using SourceKitten.
 
 - parameter filepath: The filepath to parse through SourceKitten
 - returns: A `SwiftFile` which contains the file's contents and JSON parsed through SourceKitten
 */
internal func loadSwiftFile(at filepath: String) throws -> SwiftFile {
    let sourceKittenPath: String = "/usr/local/bin/sourcekitten"
    
    guard FileManager.default.fileExists(atPath: sourceKittenPath) else {
        throw BluffaloError.sourceKittenNotFound(path: sourceKittenPath)
    }
    
    let contentsOfFile = try! String(contentsOfFile: filepath, encoding: String.Encoding.ascii)
    
    let task = Process()
    task.launchPath = "/usr/local/bin/sourcekitten"
    task.arguments = ["structure", "--file", filepath]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let read: FileHandle = pipe.fileHandleForReading
    let dataRead: Data = read.readDataToEndOfFile()
    
    guard let json = try? JSONSerialization.jsonObject(with: dataRead, options: .allowFragments) as! [String:AnyObject] else {
        throw BluffaloError.sourceKittenParseFailure
    }
    
    return SwiftFile(contents: contentsOfFile, json: json)
}

// MARK: - Private functions

/**
 Create fake class containing all of the faking/stubbing logic.
 
 */
private func createFake(at fileUrl: URL, inFile: String, outFile: String, classes: [Class], module: String?, imports: [String]?) throws {
    var code: String = ""
    
    // CLI command that can be used to regenerate the fake.
    code += "// Copy and paste the following command to regenerate this fake\n" +
    "// bluffalo -f \(inFile) -o \(outFile) \(moduleParameter(module))\n\n"

    // Additional imports
    code += additionalImports(from: imports)
    
    // Testable module import
    code += testableImport(module)
    
    // Generate source code.
    code += classes.reduce("") { (code, classStruct) -> String in
        let generator = FakeClassGenerator(classStruct: classStruct)
        return code + generator.makeFakeClass()
    }
    
    code += "\n"
    
    try write(code: code, to: fileUrl)
}

/**
 Write `code` to `fileURL`.
 */
private func write(code: String, to fileURL: URL) throws {
    try code.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
    print("I: Add fake at `\(fileURL.path)` to your project")
}

/**
 Returns the `-module` parameter if module is provided.
 */
private func moduleParameter(_ module: String?) -> String {
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
