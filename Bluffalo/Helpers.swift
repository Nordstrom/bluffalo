import Foundation

internal struct SwiftFile {
    let contents: String
    let json: [String: AnyObject]
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
        let generator = FakeClassGenerator(classStruct: classStruct)
        return code + generator.makeFakeClass() + "\n"
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
