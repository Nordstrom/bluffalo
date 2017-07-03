/**
 Responsible for parsing SourceKitten dictionaries into app objects which the generators can reason with.
 
 */

import Foundation

// MARK - Internal functions

internal func parse(file: SwiftFile) -> [ClassStruct] {
    let classStructures = getClassDictionaries(json: file.json)

    let classes: [ClassStruct] = classStructures.map { (classStructureDict: [String: AnyObject]) -> ClassStruct in
        return parseClass(json: classStructureDict, fileContents: file.contents)
    }
    
    return classes
}

internal func getClassDictionaries(json: [String: AnyObject]) -> [[String: AnyObject]] {
    var classStructures: [[String:AnyObject]] = json["key.substructure"] as! [[String:AnyObject]]
    classStructures = classStructures.filter({ (possibleClass) -> Bool in
        if let className = possibleClass["key.name"] {
            print("Possible class: \(className)")
            
            if let _ = ClassKind(rawValue: possibleClass["key.kind"]! as! String), possibleClass["key.substructure"] != nil {
                return true
            }
        }
        return false
    })
    
    return classStructures
}

internal func parseClass(json: [String: AnyObject], fileContents: String) -> ClassStruct {
    var classKind: ClassKind = .Unknown
    
    if let kind = ClassKind(rawValue: json["key.kind"]! as! String) {
        classKind = kind
    }
    
    guard let className = json["key.name"] as? String else {
        return ClassStruct(classKind: .Unknown, className: "", methods: [])
    }
    
    var methods = parseMethods(from: json, fileContents: fileContents)
    
    methods = methods.filter({ (methodStruct: Method) -> Bool in
        if methodStruct.accessibility == .Private || methodStruct.kind == .Call || methodStruct.kind == .InstanceVar || methodStruct.kind == .StaticVar {
            return false
        }
        return true
    })
    
    return ClassStruct(classKind: classKind, className: className, methods: methods)
}

// MARK - Private functions

private func parseMethods(from json: [String: AnyObject], fileContents: String) -> [Method] {
    guard let substructures: [[String:AnyObject]] = json["key.substructure"] as? [[String:AnyObject]] else {
        return []
    }
    
    let methodDicts = substructures.filter { substructure in
        return ClassKind(rawValue: substructure["key.kind"] as! String) == nil
    }
    
    let methods: [Method] = methodDicts.map { (methodStructureDict: [String : AnyObject]) -> Method in
        var methodKind: MethodKind = .Instance
        var methodAccessibility: MethodAccessibility = .Private
        var argumentNames: [String] = []
        var argumentTypes: [String] = []
        
        guard let methodName = methodStructureDict["key.name"] as? String else {
            return Method(name: "", nameWithExternalNames: "", kind: methodKind, accessibility: .Private, argumentNames: argumentNames, externalArgumentNames: [String](), argumentTypes: argumentTypes, returnType: "")
        }
        
        // Kind
        if let kind: MethodKind = MethodKind(rawValue:(methodStructureDict["key.kind"] as? String)!) {
            methodKind = kind
        }
        
        // Accessibility
        var methodAccesibilityValue: String?
        if let _ = methodStructureDict["key.accessibility"] as? String {
            methodAccesibilityValue = methodStructureDict["key.accessibility"] as? String
        }
        else {
            methodAccesibilityValue = methodStructureDict["key.setter_accessibility"] as? String
        }
        
        if methodAccesibilityValue != nil {
            methodAccessibility = MethodAccessibility(rawValue:methodAccesibilityValue!)!
        }
        
        // Arguments
        if let arguments = methodStructureDict["key.substructure"] as? [[String:AnyObject]] {
            arguments.forEach({ (argumentStructureDictionary: [String : AnyObject]) in
                if let argumentType: String = argumentStructureDictionary["key.typename"] as? String {
                    if let argumentName: String = argumentStructureDictionary["key.name"] as? String {
                        argumentNames.append(argumentName)
                        let refinedArgumentType: String = argumentType.replacingOccurrences(of: "!", with: "")
                        argumentTypes.append(refinedArgumentType)
                    }
                }
            })
        }
        
        // Signature
        var methodSignature = methodName
        methodSignature = methodSignature.replacingOccurrences(of: ":", with: ":, ")
        methodSignature = methodSignature.replacingOccurrences(of: ":, )", with: ":)")
        let externalArgumentNames = getExternalArgumentsFromMethodName(name: methodName) ?? argumentNames
        let externalArgumentNamesWithInternalBackup = getExternalArgumentsFromMethodNameWithInternalNameBackup(name: methodName, internalArgumentNames: argumentNames) ?? argumentNames
        let i: Int = 0
        for i in i..<externalArgumentNames.count {
            let argumentToReplace: String = "\(externalArgumentNames[i]):"
            let argumentType: String = argumentTypes[i]
            var argumentToUse: String = "\(externalArgumentNamesWithInternalBackup[i]): \(argumentType)"
            if externalArgumentNames[i] == "_" {
                argumentToUse = "_ \(externalArgumentNamesWithInternalBackup[i]): \(argumentType)"
            }
            
            methodSignature = methodSignature.replacingOccurrences(of: argumentToReplace, with: argumentToUse)
        }
        
        // Return type
        let returnType = returnTypeFromMethod(json: methodStructureDict, fileContents: fileContents)
        
        return Method(
            name: methodName,
            nameWithExternalNames: methodSignature,
            kind: methodKind,
            accessibility: methodAccessibility,
            argumentNames: argumentNames,
            externalArgumentNames: externalArgumentNamesWithInternalBackup,
            argumentTypes: argumentTypes,
            returnType: returnType
        )
    }
    
    return methods
}

private func getExternalArgumentsFromMethodName(name: String) -> [String]? {
    var externalArgumentNames: [String]?
    do {
        let regex = try NSRegularExpression(pattern: "(?<=\\().+?(?=\\))", options: [])
        let nsString = name as NSString
        
        let results = regex.matches(in: name,
                                    options: [], range: NSMakeRange(0, nsString.length))
        let argumentsInMethodName = results.map { nsString.substring(with: $0.range)}
        externalArgumentNames = argumentsInMethodName.first?.components(separatedBy: ":")
        externalArgumentNames?.removeLast()
    }
    catch {
        print(error)
    }
    
    return externalArgumentNames
}

private func returnTypeFromMethod(json: [String: AnyObject], fileContents : String) -> String? {
    let start = json["key.offset"] as! Int
    let length = json["key.length"] as! Int
    
    let startIndex = fileContents.index(fileContents.startIndex, offsetBy: start)
    
    let endIndex = fileContents.index(startIndex, offsetBy: length)
    
    let funcDeclarationString = fileContents.substring(with: Range(uncheckedBounds: (lower: startIndex, upper: endIndex)))
    
    
    var parenthesesCount = 0
    var foundFirstParen: Bool = false
    var remainingFunctionString: String = ""
    
    for characterIndex in funcDeclarationString.characters.indices {
        let character = funcDeclarationString.characters[characterIndex]
        if character == "(" {
            parenthesesCount += 1
            foundFirstParen = true
        }
        else if character == ")" {
            parenthesesCount -= 1
        }
        
        if foundFirstParen && parenthesesCount == 0 {
            remainingFunctionString = funcDeclarationString.substring(from: characterIndex)
            break
        }
    }
    
    guard let arrowLocation = remainingFunctionString.range(of: "->") else {
        return nil
    }
    
    
    let endOfReturnTypeRange = remainingFunctionString.range(of: "{")
    var endOfReturnTypeIndex: String.Index
    
    if endOfReturnTypeRange == nil {
        endOfReturnTypeIndex = remainingFunctionString.endIndex
    }
    else {
        endOfReturnTypeIndex = (endOfReturnTypeRange?.lowerBound)!
    }
    
    let returnTypeRange = Range<String.Index>(uncheckedBounds: (lower: (arrowLocation.upperBound), upper: endOfReturnTypeIndex))
    let returnType = remainingFunctionString.substring(with: returnTypeRange).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
    let refinedReturnType = returnType.replacingOccurrences(of: "!", with: "")
    
    return refinedReturnType
}

private func getExternalArgumentsFromMethodNameWithInternalNameBackup(name: String, internalArgumentNames: [String]) -> [String]? {
    var externalArgumentNames: [String]?
    do {
        let regex = try NSRegularExpression(pattern: "(?<=\\().+?(?=\\))", options: [])
        let nsString = name as NSString
        
        let results = regex.matches(in: name,
                                    options: [], range: NSMakeRange(0, nsString.length))
        let argumentsInMethodName = results.map { nsString.substring(with: $0.range)}
        externalArgumentNames = argumentsInMethodName.first?.components(separatedBy: ":")
        externalArgumentNames?.removeLast()
        if let numberOfExternalArguments = externalArgumentNames?.count {
            for myIndex in 0..<numberOfExternalArguments {
                if externalArgumentNames![myIndex] == "_" {
                    externalArgumentNames![myIndex] = internalArgumentNames[myIndex]
                }
            }
        }
    }
    catch {
        print(error)
    }
    
    return externalArgumentNames
}
