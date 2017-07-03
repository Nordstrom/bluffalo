import Foundation

// Next up: split out the app-wrapper from file generation. 
// Make a parameterized WriteOneFake() method.
// Add support for new fake:source sytax in list file

let usageText = [
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

func printUsageText() {
    _ = usageText.map({print($0)})
}

class GeneratorApp {
    let fileGenerator = FileGenerator()
    
    func main(arguments:[String]) -> Int32 {
        guard arguments.count > 0 else {
            print("missing argument array")
            return 2
        }
        
        guard arguments.count > 1 else {
            print("Missing arguments. -? for help.")
            return 1
        }
        
        var argumentNumber = 0
        var sourcesFile: String?
        
        //Execution
        for arg in arguments {
            if arg == "-help" || arg == "-h" || arg == "-?" {
                printUsageText()
                return 1
            }
            if arg == "-list" {
                fileGenerator.listOfFilesFile = arguments[argumentNumber + 1]
            }
            if arg == "-outputDirectory" {
                fileGenerator.outputDirectory = arguments[argumentNumber + 1]
            }
            if arg == "-module" {
                fileGenerator.testableModule = arguments[argumentNumber + 1]
            }
            if arg == "-file" {
                fileGenerator.file = arguments[argumentNumber + 1]
            }
            if arg == "-outputFile" {
                fileGenerator.outputFile = arguments[argumentNumber+1]
            }
            if arg == "-imports" {
                fileGenerator.listOfImports = arguments[argumentNumber+1]
            }
            if arg == "-sources" {
                sourcesFile = arguments[argumentNumber+1]
            }
            argumentNumber += 1
        }
        
        var errors = 0
        if let sources = sourcesFile {
            errors += handleSourcesFile(sources)
        }
        else {
            do {
                try fileGenerator.generate()
            }
            catch {
                errors += 1
            }
        }
        
        return (errors == 0) ? 0 : 5
    }
    
    private func handleSourcesFile(_ sourcesFile: String) -> Int {
        var errors = 0
        print("Consuming sources file: \(sourcesFile)")
        if let contentsOfFile = try? String(contentsOfFile: sourcesFile) {
            let lines = contentsOfFile.components(separatedBy: "\n")
            print("Found \(lines.count) sources")
            for line in lines where line.characters.count > 0 {
                let parts = line.components(separatedBy: CharacterSet(charactersIn: ":"))
                if parts.count == 2 {
                    let fakeName = parts[0]
                    let fileName = parts[1]
                    print("\"\(fileName)\" -> \"\(fakeName)\"")
                    fileGenerator.outputFile = fakeName
                    fileGenerator.file = fileName
                    
                    do {
                        try fileGenerator.generate()
                    }
                    catch {
                        errors += 1
                    }
                }
                else if parts.count == 0 {
                    print("Ignoring empty source line")
                }
                else {
                    print("Invalid source line with \(parts.count) parts: \"\(line)\"")
                    errors += 1
                }
            }
        }
        else {
            print("Dang! The sources file was was empty")
            errors += 1
        }
        
        return errors
    }
}
