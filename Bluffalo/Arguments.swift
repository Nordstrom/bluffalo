import Foundation

/**
 Arguments that can be passed into the application from the command line.
 */
struct Arguments {
    let file: String
    let outFile: String
    let module: String?
    
    private var _imports: [String]?
    var imports: [String]? {
        return _imports
    }
    
    init(file: String, outFile: String, module: String?, imports: String?) {
        self.file = file
        self.outFile = outFile
        self.module = module
        
        self._imports = parseImports(imports)
    }
    
    /**
     Returns list of imports parsed from `imports`.
     */
    public func parseImports(_ imports: String?) -> [String]? {
        guard let imports = imports else {
            return nil
        }
        
        let modules: [String] = imports.components(separatedBy: ",").flatMap { (importName) -> String? in
            importName.trimmingCharacters(in: NSCharacterSet.whitespaces)
        }
        return modules
    }
}
