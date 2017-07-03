import Foundation

private struct Constant {
    static let equalityFunction = "checkEquality"
}

private func stringForMethodKind(methodKind: MethodKind) -> String {
    switch methodKind {
    case .Class: return "class func"
    case .Instance: return "func"
    case .Static: return "static func"
    case .InstanceVar: return "var"
    case .Call: return ""
    case .StaticVar: return "static var"
    }
}

class FakeClassGenerator {
    private let tab = "    "
    private let classFunctionsAndArgumentsCalledString: String = "classFunctionsAndArgumentsCalled"
    private let functionsAndArgumentsCalledString: String = "functionsAndArgumentsCalled"
    
    internal var classStructure: ClassStruct
    
    internal var enumName: String {
        get {
            return "\(classStructure.className)Method"
        }
    }
    
    init(classStruct: ClassStruct) {
        self.classStructure = classStruct
    }
    
    // MARK - Public functions
    
    func makeFakeClass() -> String {
        let className: String = classStructure.className
        classStructure.methods = classStructure.methods.filter { (method: Method) -> Bool in
            if method.name.contains("init(") {
                return false
            }
            
            return true
        }
        
        guard classStructure.methods.count > 0 else {
            return ""
        }
        
        var fakeString = ""
        
        fakeString += generateEquatableEnumerationForMethods()
        fakeString += "\n"
        fakeString += generateEquatableMethod()
        fakeString += "\n"
        fakeString += generateStub()
        fakeString += "\n"
        fakeString += generateReturn()
        fakeString += "\n"
        
        var classString = "class Fake\(className): \(className) {\n"
        
        classString += tab + "var stubs = [(Any,Any)]()\n"
        classString += tab + "static var classStubs = [AnyHashable: Any]()\n"
        classString += tab + "private var methodCalls = [Any]()\n"
        classString += tab + "private static var classMethodCalls = [Any]()\n"
        classString += "\n"
        
        classString += generateStubHelpers()
        
        for method in classStructure.methods {
            
            if let _ = enumNameForMethod(method: method) {
                let methodKindString = stringForMethodKind(methodKind: method.kind)
                
                var overrideString: String = ""
                
                if classStructure.classKind == .ClassKind {
                    overrideString = "override"
                }
                
                classString += tab + "\(overrideString) \(methodKindString) \(method.nameWithExternalNames)"
                
                var stubGeneric = "Any"
                if let returnType = method.returnType {
                    classString += " -> " + returnType + " "
                    stubGeneric = returnType
                }
                
                classString += "{\n"
                
                var parameters = "nil"
                if method.externalArgumentNames.count > 0 {
                    parameters = "["
                    for argument in method.externalArgumentNames {
                        parameters += "\"\(argument)\": \(argument),"
                    }
                    parameters += "]"
                }
                
                let methodEnum = generateEnumWithPassedInParameters(forMethod: method)
                classString += tab + tab + "let stub = \(classStructure.className)Stub<\(stubGeneric)>(method: \(methodEnum))\n"
                
                switch method.kind {
                case .Class:
                    classString += tab + tab + "classMethodCalls.append(stub)\n"
                case .Instance:
                    classString += tab + tab + "methodCalls.append(stub)\n"
                default:
                    break
                }
                
                if let returnType = method.returnType {
                    switch method.kind {
                    case .Class:
                        classString += tab + tab + "return classStubs[stub] as! \(returnType)\n"
                    case .Instance:
                        classString += tab + tab + "return returnFor(stub: stub) as! \(returnType)\n"
                    default:
                        break
                    }
                    
                }
                classString += tab + "}\n"
                classString += "\n"
            }
        }
        
        classString += tab + "func stub<T>(_ stub: \(classStructure.className)Stub<T>) -> \(classStructure.className)Return<T> {\n"
        classString += tab + tab + "return \(classStructure.className)Return<T>(fake: self, stub: stub)\n"
        classString += tab + "}\n"
        
        classString += "\n"
        classString += tab + "class func stub<T>(_ stub: \(classStructure.className)Stub<T>) -> \(classStructure.className)ClassReturn<T> {\n"
        classString += tab + tab + "return \(classStructure.className)ClassReturn<T>(stub: stub)\n"
        classString += tab + "}\n"
        
        classString += "\n"
        
        classString += generateMatchingMethods()
        
        classString += tab + "func didCall<T>(method: \(classStructure.className)Stub<T>) -> Bool {\n"
        classString += tab + tab + "return matchingMethods(method).count > 0\n"
        classString += tab + "}\n"
        classString += "\n"
        
        classString += tab + "class func didCall<T>(method: \(classStructure.className)Stub<T>) -> Bool {\n"
        classString += tab + tab + "return matchingMethods(method).count > 0\n"
        classString += tab + "}\n"
        classString += "\n"
        
        classString += "}\n"
        
        fakeString += classString
        
        return fakeString
    }
    
    // MARK - Private functions
    
    private func enumNameForMethod(method: Method) -> String? {
        let startOfStringToRemove = method.name.range(of: "(")
        
        if let startIndex = startOfStringToRemove {
            var methodSignature: String = method.name.substring(to: startIndex.lowerBound)
            for arg in method.externalArgumentNames {
                methodSignature += "_" + arg
            }
            
            return methodSignature
        }
        
        return nil
    }
    
    private func generateEquatableEnumerationForMethods() -> String {
        var text: String = "public enum \(enumName): Equatable, Hashable {\n"
        for method: Method in classStructure.methods {
            
            if let methodName = enumNameForMethod(method: method) {
                text += "\(tab)case " + methodName
                text += "("
                
                var needsComma: Bool = false
                for type: String in method.argumentTypes {
                    if needsComma {
                        text += ", "
                    }
                    needsComma = true
                    
                    text += "\(type)"
                }
                text += ")\n"
            }
        }
        
        text += "\(tab)public var hashValue: Int {\n"
        text += "\(tab)\(tab)get {\n"
        text += tab + tab + tab + "switch self {\n"
        
        var hashValue: Int = 0
        for method: Method in classStructure.methods {
            if let methodName = enumNameForMethod(method: method) {
                text += tab + tab + tab + "case .\(methodName):\n"
                text += tab + tab + tab + tab + "return \(hashValue)\n"
                hashValue += 1
            }
        }
        
        text += tab + tab + tab + "}\n"
        text += tab + tab + "}\n"
        text += tab + "}\n"
        
        text += "}\n"
        return text
    }
    
    private func generateEquatableMethod() -> String {
        var text: String = ""
        text += "public func == (lhs: \(enumName), rhs: \(enumName)) -> Bool {\n"
        text += "\(tab)switch (lhs, rhs) {\n"
        
        for method: Method in classStructure.methods {
            if let methodName = enumNameForMethod(method: method) {
                text += "\(tab)"
                text += "case (.\(methodName)("
                let numberOfArguments: Int = method.argumentTypes.count
                if numberOfArguments > 0 {
                    for i in 1...numberOfArguments {
                        if i > 1 {
                            text += ", "
                        }
                        text += "let a\(i)"
                    }
                }
                
                text += "), "
                
                text += ".\(methodName)("
                if numberOfArguments > 0 {
                    for i in 1...numberOfArguments {
                        if i > 1 {
                            text += ", "
                        }
                        text += "let b\(i)"
                    }
                }
                
                text += ")): return "
                
                if numberOfArguments > 0 {
                    var isFirstArgument: Bool = true
                    for i in 1...numberOfArguments {
                        if !isFirstArgument {
                            text += " && "
                        }
                        
                        if method.argumentTypes[i - 1].contains("AnyObject") {
                            text += Constant.equalityFunction + "(a\(i), b: b\(i))"
                        }
                        else {
                            text += "a\(i) == b\(i)"
                        }
                        
                        isFirstArgument = false
                    }
                }
                else {
                    text += "true"
                }
                
                text += "\n"
                
            }
        }
        
        if classStructure.methods.count > 1 {
            text += "\n"
            for method: Method in classStructure.methods {
                if let methodName = enumNameForMethod(method: method) {
                    text += "\(tab)case (.\(methodName), _): return false"
                    text += "\n"
                }
            }
        }
        
        text += "\(tab)}\n"
        text += "}"
        
        return text
    }
    
    private func generateMatchingMethods() -> String {
        var matchingMethodString = tab + "func matchingMethods<T>(_ stub: \(classStructure.className)Stub<T>) -> [Any] {\n"
        matchingMethodString += tab + tab + "let callsToMethod = methodCalls.filter { object in\n"
        matchingMethodString += tab + tab + tab + "if let theMethod = object as? \(classStructure.className)Stub<T> {\n"
        matchingMethodString += tab + tab + tab + tab + "return theMethod == stub\n"
        matchingMethodString += tab + tab + tab + "}"
        matchingMethodString += "\n"
        matchingMethodString += tab + tab + tab + "return false\n"
        matchingMethodString += tab + tab + "}\n"
        matchingMethodString += tab + tab + "return callsToMethod\n"
        matchingMethodString += tab + "}\n"
        matchingMethodString += tab + "\n"
        
        matchingMethodString += tab + "class func matchingMethods<T>(_ stub: \(classStructure.className)Stub<T>) -> [Any] {\n"
        matchingMethodString += tab + tab + "let callsToMethod = classMethodCalls.filter { object in\n"
        matchingMethodString += tab + tab + tab + "if let theMethod = object as? \(classStructure.className)Stub<T> {\n"
        matchingMethodString += tab + tab + tab + tab + "return theMethod == stub\n"
        matchingMethodString += tab + tab + tab + "}"
        matchingMethodString += "\n"
        matchingMethodString += tab + tab + tab + "return false\n"
        matchingMethodString += tab + tab + "}\n"
        matchingMethodString += tab + tab + "return callsToMethod\n"
        matchingMethodString += tab + "}\n"
        matchingMethodString += "\n"
        
        return matchingMethodString
    }
    
    private func generateStub() -> String {
        var stubString = "struct \(classStructure.className)Stub<T>: Hashable, Equatable {\n"
        stubString += tab + "var method: \(classStructure.className)Method\n"
        stubString += tab + "var hashValue: Int {\n"
        stubString += tab + tab + "return method.hashValue\n"
        stubString += tab + "}\n"
        
        stubString += "\n"
        
        stubString += tab + "init(method: \(classStructure.className)Method) {\n"
        stubString += tab + tab + "self.method = method\n"
        stubString += tab + "}\n"
        
        stubString += "\n"
        
        stubString += tab + "public static func == (lhs: \(classStructure.className)Stub, rhs: \(classStructure.className)Stub) -> Bool {\n"
        stubString += tab + tab + "return lhs.method == rhs.method\n"
        stubString += tab + "}\n"
        
        for method in classStructure.methods {
            if let _ = enumNameForMethod(method: method) {
                stubString += tab + "public static func " + method.nameWithExternalNames
                
                var stubGeneric = "Any"
                if let returnType = method.returnType {
                    stubGeneric = returnType
                }
                stubString += " -> \(classStructure.className)Stub<\(stubGeneric)>"
                stubString += " {\n"
                
                var parameters = "nil"
                if method.externalArgumentNames.count > 0 {
                    parameters = "["
                    for argument in method.externalArgumentNames {
                        parameters += "\"\(argument)\": \(argument),"
                    }
                    parameters += "]"
                }
                
                let methodEnum = generateEnumWithPassedInParameters(forMethod: method)
                stubString += tab + tab + "return \(classStructure.className)Stub<\(stubGeneric)>(method: \(methodEnum))\n"
                stubString += tab + "}\n"
                stubString += "\n"
            }
        }
        
        stubString += "}\n"
        
        return stubString
    }
    
    private func generateEnumWithPassedInParameters(forMethod method: Method) -> String {
        var text = ""
        if let methodName =  enumNameForMethod(method: method) {
            text += ".\(methodName)("
            
            var needsComma: Bool = false
            for argumentName: String in method.externalArgumentNames {
                if needsComma {
                    text += ", "
                }
                text += "\(argumentName)"
                needsComma = true
            }
            
            text += ")"
            
            return text
        }
        
        return ""
    }
    
    private func generateReturn() -> String {
        var returnString = "struct \(classStructure.className)Return<T> {\n"
        returnString += tab + "var fake: Fake" + classStructure.className + "\n"
        returnString += tab + "var stub: \(classStructure.className)Stub<T>\n"
        returnString += "\n"
        returnString += tab + "func andReturn(_ value: T) {\n"
        returnString += tab + tab + "fake.setReturnFor(stub: stub, value: value)\n"
        returnString += tab + "}\n"
        returnString += "}\n"
        
        returnString += "\n"
        
        returnString += "struct \(classStructure.className)ClassReturn<T> {\n"
        returnString += tab + "var stub: \(classStructure.className)Stub<T>\n"
        returnString += "\n"
        returnString += tab + "func andReturn(_ value: T) {\n"
        returnString += tab + tab + "Fake\(classStructure.className).classStubs[stub] = value\n"
        returnString += tab + "}\n"
        returnString += "}\n"
        
        return returnString
    }
    
    private func generateStubHelpers() -> String {
        var text = ""
        text += tab + "func returnFor<T>(stub: \(classStructure.className)Stub<T>) -> Any? {\n"
        text += tab + tab + "for tuple in stubs {\n"
        text += tab + tab + tab + "if let myStub = tuple.0 as? \(classStructure.className)Stub<T> {\n"
        text += tab + tab + tab + tab + "if myStub == stub {\n"
        text += tab + tab + tab + tab + tab + "return tuple.1\n"
        text += tab + tab + tab + tab + "}\n"
        text += tab + tab + tab + "}\n"
        text += tab + tab + "}\n"
        text += tab + tab + "return nil\n"
        text += tab + "}\n"
        
        text += "\n"
        
        text += tab + "func setReturnFor<T>(stub: \(classStructure.className)Stub<T>, value: Any) {\n"
        text += tab + tab + "stubs.append((stub, value))\n"
        text += tab + "}\n"
        
        return text
    }
}
