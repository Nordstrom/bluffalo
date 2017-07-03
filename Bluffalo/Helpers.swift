import Foundation

func getJSONForFilePath(filepath:String) -> [String:AnyObject] {
    let sourceKittenPath: String = "/usr/local/bin/sourcekitten"
    
    guard FileManager.default.fileExists(atPath: sourceKittenPath) else {
        print("Error! SourceKitten does not exist at path: \(sourceKittenPath)")
        print("Install SourceKitten with 'brew install sourcekitten'")
        exit(1)
    }
    
    contentsOfFile = try! String(contentsOfFile: filepath)
    
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
    
    return json
}

func getClassDictionaries(json: [String: AnyObject]) -> [[String: AnyObject]] {
    var classStructures: [[String:AnyObject]] = json["key.substructure"] as! [[String:AnyObject]]
    classStructures = classStructures.filter({ (possibleClass) -> Bool in
        print(possibleClass["key.name"])
        
        if let _ = ClassKind(rawValue: possibleClass["key.kind"]! as! String) , possibleClass["key.substructure"] != nil {
            return true
        }
        
        return false
    })
    
    return classStructures
}

func createFakeClassForFile(filePath: String) ->String {
    
    let json = getJSONForFilePath(filepath: filePath)
    
    let classStructures = getClassDictionaries(json: json)
    
    let classes: [ClassStruct] = classStructures.map { (classStructureDict: [String : AnyObject]) -> ClassStruct in
        let parser = Parser(json: classStructureDict)
        
        return parser.parse()
    }
    
    var classText = ""
    for classStructure in classes {
        let generator = FakeClassGenerator(classStruct: classStructure)
        
        classText += generator.makeFakeClass() + Constant.newLine
    }
    
    return classText
}

func writeStringToFile(stringToWrite: String, outputDirectory: String, outputFile outputFilename: String) {
    
    do {
        var outputFile = outputFilename
        if outputFile.characters.count == 0 {
            outputFile = "Fakes.swift"
        }
        let file: String = outputDirectory + outputFile
        let fileURL = URL(fileURLWithPath: file)
        try stringToWrite.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
        print("Add \(fileURL.absoluteURL) to your project")
    }
    catch {
        print("Failed to write file")
    }
}

func getImportsForFile(path: String) -> [String] {
    let fileString = try! String(contentsOfFile: path)
    
    let results = try! NSRegularExpression(pattern: "import \\w+", options: .anchorsMatchLines).matches(in: fileString, options: .reportCompletion, range: NSRange(location: 0, length: fileString.characters.count))
    
    let imports = results.map { result -> String in
        let startIndex = fileString.index(fileString.startIndex, offsetBy: result.range.location)
        let endIndex = fileString.index(startIndex, offsetBy: result.range.length)
        let range = Range(uncheckedBounds: (startIndex, endIndex))
        return fileString.substring(with: range)
    }
    
    return imports
}
