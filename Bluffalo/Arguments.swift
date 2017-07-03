import Foundation

/**
 Arguments that can be passed into the application from the command line.
 */
struct Arguments {
    let file: String
    let outputFile: String
    let module: String?
    let imports: String?
    
    /**
     Returns list of imports parsed from `imports`.
     */
    public func importList() -> [String]? {
        guard let imports = imports else {
            return nil
        }
        
        let modules: [String] = imports.components(separatedBy: ",").flatMap { (importName) -> String? in
            importName.trimmingCharacters(in: NSCharacterSet.whitespaces)
        }
        return modules
    }
}
