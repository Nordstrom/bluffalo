/*
 * Arguments.swift
 * Copyright (c) 2017 Nordstrom, Inc. All rights reserved
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
     
     - parameter imports: The list of additional `imports` to add to the top of a generated file.
     - returns: A parsed list of imports to include at the top of a generated file.
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
