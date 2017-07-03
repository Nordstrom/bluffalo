import Foundation

func printUsageText() {

}

class GeneratorApp {
    let fileGenerator = FileGenerator()
    
    func main(arguments: Arguments) -> Int32 {        
        var errors = 0
        do {
            try fileGenerator.generate(file: arguments.file, outFile: arguments.outputFile, module: arguments.module, imports: arguments.importList())
        }
        catch {
            errors += 1
        }
        
        return (errors == 0) ? 0 : 5
    }
}
