/*
 * FakeClassGenerator.swift
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
 Responsible for generating fake classes.
 */
class FakeClassGenerator {
    private let tab = "    "
    private let classFunctionsAndArgumentsCalledString: String = "classFunctionsAndArgumentsCalled"
    private let functionsAndArgumentsCalledString: String = "functionsAndArgumentsCalled"
    private let equalityFunction = "checkEquality"

    private let classStruct: Class
    
    private var className: String {
        return classStruct.name
    }
    
    private var classKind: ClassKind {
        return classStruct.kind
    }
    
    private var methods: [Method] {
        return classStruct.methods
    }
    
    private var enumName: String {
        return classStruct.enumName
    }
    
    init(classStruct: Class) {
        self.classStruct = classStruct
    }
    
    // MARK - Public functions
    
    func makeFakeClass() -> String {
        guard methods.count > 0 else {
            return ""
        }
        
        let fakeHelpers = generateFakeHelpers()
        let fakeClass = generateFakeClass()
        
        return fakeHelpers + fakeClass
    }
    
    // MARK - Private functions
    
    private func generateFakeHelpers() -> String {
        var code: String = ""
        code += generateEquatableEnumerationForMethods()
        code += "\n"
        code += generateEquatableMethod()
        code += "\n"
        code += generateStub()
        code += "\n"
        code += generateReturn()
        code += "\n"

        return code
    }
    
    private func generateFakeClass() -> String {
        var code = "class Fake\(className): \(className) {\n"
        
        code += generateStubHelpers()
        
        for method in methods {
            if let _ = enumNameForMethod(method: method) {
                code += generateStubFor(method: method)
            }
        }
        
        code += "}\n"
        
        return code
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

    private func generateStubFor(method: Method) -> String {
        var code: String = ""
        
        let methodKindString = stringForMethodKind(methodKind: method.kind)
        
        var overrideString: String = ""
        
        if classKind == .ClassKind {
            overrideString = "override "
        }
        
        code += tab + "\(overrideString)\(methodKindString) \(method.nameWithExternalNames)"
        
        var stubGeneric = "Any"
        if let returnType = method.returnType {
            code += " -> " + returnType
            stubGeneric = returnType
        }
        
        code += " {\n"
        
        var parameters = "nil"
        if method.externalArgumentNames.count > 0 {
            parameters = "["
            for argument in method.externalArgumentNames {
                parameters += "\"\(argument)\": \(argument),"
            }
            parameters += "]"
        }
        
        let methodEnum = generateEnumWithPassedInParameters(for: method)
        code += tab + tab + "let stub = \(className)Stub<\(stubGeneric)>(method: \(methodEnum))\n"
        
        switch method.kind {
        case .Class:
            code += tab + tab + "classMethodCalls.append(stub)\n"
        case .Instance:
            code += tab + tab + "methodCalls.append(stub)\n"
        default:
            break
        }
        
        if let returnType = method.returnType {
            switch method.kind {
            case .Class:
                code += tab + tab + "return classStubs[stub] as! \(returnType)\n"
            case .Instance:
                code += tab + tab + "return returnFor(stub: stub) as! \(returnType)\n"
            default:
                break
            }
            
        }
        code += tab + "}\n"
        code += "\n"
        
        return code
    }
    
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
        var code: String = "public enum \(enumName): Equatable, Hashable {\n"
        
        for method: Method in methods {
            if let methodName = enumNameForMethod(method: method) {
                code += tab + "case " + methodName
                code += "("
                
                var needsComma: Bool = false
                for type: String in method.argumentTypes {
                    if needsComma {
                        code += ", "
                    }
                    needsComma = true
                    
                    code += "\(type)"
                }
                code += ")\n"
            }
        }
        
        code += tab + "public var hashValue: Int {\n"
        code += tab + tab + "get {\n"
        code += tab + tab + tab + "switch self {\n"
        
        var hashValue: Int = 0
        for method: Method in methods {
            if let methodName = enumNameForMethod(method: method) {
                code += tab + tab + tab + "case .\(methodName):\n"
                code += tab + tab + tab + tab + "return \(hashValue)\n"
                hashValue += 1
            }
        }
        
        code += tab + tab + tab + "}\n"
        code += tab + tab + "}\n"
        code += tab + "}\n"
        code += "}\n"
        
        return code
    }
    
    private func generateEquatableMethod() -> String {
        var code: String = ""
        code += "public func == (lhs: \(enumName), rhs: \(enumName)) -> Bool {\n"
        code += tab + "switch (lhs, rhs) {\n"
        
        for method: Method in methods {
            if let methodName = enumNameForMethod(method: method) {
                code += tab + "case (.\(methodName)("
                let numberOfArguments: Int = method.argumentTypes.count
                if numberOfArguments > 0 {
                    for i in 1...numberOfArguments {
                        if i > 1 {
                            code += ", "
                        }
                        code += "let a\(i)"
                    }
                }
                
                code += "), "
                
                code += ".\(methodName)("
                if numberOfArguments > 0 {
                    for i in 1...numberOfArguments {
                        if i > 1 {
                            code += ", "
                        }
                        code += "let b\(i)"
                    }
                }
                
                code += ")): return "
                
                if numberOfArguments > 0 {
                    var isFirstArgument: Bool = true
                    for i in 1...numberOfArguments {
                        if !isFirstArgument {
                            code += " && "
                        }
                        
                        if method.argumentTypes[i - 1].contains("AnyObject") {
                            code += equalityFunction + "(a\(i), b: b\(i))"
                        }
                        else {
                            code += "a\(i) == b\(i)"
                        }
                        
                        isFirstArgument = false
                    }
                }
                else {
                    code += "true"
                }
                
                code += "\n"
                
            }
        }
        
        if methods.count > 1 {
            code += "\n"
            for method: Method in methods {
                if let methodName = enumNameForMethod(method: method) {
                    code += tab + "case (.\(methodName), _): return false"
                    code += "\n"
                }
            }
        }
        
        code += tab + "}\n"
        code += "}\n"
        
        return code
    }
    
    private func generateStub() -> String {
        var code: String = ""
        code = "struct \(className)Stub<T>: Hashable, Equatable {\n"
        code += tab + "var method: \(className)Method\n"
        code += tab + "var hashValue: Int {\n"
        code += tab + tab + "return method.hashValue\n"
        code += tab + "}\n"
        code += "\n"
        
        code += tab + "init(method: \(className)Method) {\n"
        code += tab + tab + "self.method = method\n"
        code += tab + "}\n"
        code += "\n"
        
        code += tab + "public static func == (lhs: \(className)Stub, rhs: \(className)Stub) -> Bool {\n"
        code += tab + tab + "return lhs.method == rhs.method\n"
        code += tab + "}\n\n"
        
        for method in methods {
            if let _ = enumNameForMethod(method: method) {
                code += tab + "public static func " + method.nameWithExternalNames
                
                var stubGeneric = "Any"
                if let returnType = method.returnType {
                    stubGeneric = returnType
                }
                code += " -> \(className)Stub<\(stubGeneric)>"
                code += " {\n"
                
                var parameters = "nil"
                if method.externalArgumentNames.count > 0 {
                    parameters = "["
                    for argument in method.externalArgumentNames {
                        parameters += "\"\(argument)\": \(argument),"
                    }
                    parameters += "]"
                }
                
                let methodEnum = generateEnumWithPassedInParameters(for: method)
                code += tab + tab + "return \(className)Stub<\(stubGeneric)>(method: \(methodEnum))\n"
                code += tab + "}\n"
                code += "\n" // TODO: Should not be added to the last generated func.
            }
        }
        
        code += "}\n"
        
        return code
    }
    
    private func generateEnumWithPassedInParameters(for method: Method) -> String {
        guard let methodName = enumNameForMethod(method: method) else {
            return ""
        }
        
        var code = ""
        code += ".\(methodName)("
        
        var needsComma: Bool = false
        for argumentName: String in method.externalArgumentNames {
            if needsComma {
                code += ", "
            }
            code += "\(argumentName)"
            needsComma = true
        }
        
        code += ")"
        
        return code
    }
    
    private func generateReturn() -> String {
        var code: String = ""
        code += "struct \(className)Return<T> {\n"
        code += tab + "var fake: Fake" + className + "\n"
        code += tab + "var stub: \(className)Stub<T>\n"
        code += "\n"
        code += tab + "func andReturn(_ value: T) {\n"
        code += tab + tab + "fake.setReturnFor(stub: stub, value: value)\n"
        code += tab + "}\n"
        code += "}\n"
        code += "\n"
        
        code += "struct \(className)ClassReturn<T> {\n"
        code += tab + "var stub: \(className)Stub<T>\n"
        code += "\n"
        code += tab + "func andReturn(_ value: T) {\n"
        code += tab + tab + "Fake\(className).classStubs[stub] = value\n"
        code += tab + "}\n"
        code += "}\n"
        
        return code
    }
    
    /**
     Generate stub helpers.
     
     TODO: This could be in a template file and interpolated with respective `ClassStruct` values.
     
     */
    private func generateStubHelpers() -> String {
        var code: String = ""
        code += tab + "var stubs = [(Any,Any)]()\n"
        code += tab + "static var classStubs = [AnyHashable: Any]()\n"
        code += tab + "private var methodCalls = [Any]()\n"
        code += tab + "private static var classMethodCalls = [Any]()\n\n"

        code += tab + "func returnFor<T>(stub: \(className)Stub<T>) -> Any? {\n"
        code += tab + tab + "for tuple in stubs {\n"
        code += tab + tab + tab + "if let myStub = tuple.0 as? \(className)Stub<T> {\n"
        code += tab + tab + tab + tab + "if myStub == stub {\n"
        code += tab + tab + tab + tab + tab + "return tuple.1\n"
        code += tab + tab + tab + tab + "}\n"
        code += tab + tab + tab + "}\n"
        code += tab + tab + "}\n"
        code += tab + tab + "return nil\n"
        code += tab + "}\n\n"
        
        code += tab + "func setReturnFor<T>(stub: \(className)Stub<T>, value: Any) {\n"
        code += tab + tab + "stubs.append((stub, value))\n"
        code += tab + "}\n\n"
        
        code += tab + "func stub<T>(_ stub: \(className)Stub<T>) -> \(className)Return<T> {\n"
        code += tab + tab + "return \(className)Return<T>(fake: self, stub: stub)\n"
        code += tab + "}\n\n"
        
        code += tab + "class func stub<T>(_ stub: \(className)Stub<T>) -> \(className)ClassReturn<T> {\n"
        code += tab + tab + "return \(className)ClassReturn<T>(stub: stub)\n"
        code += tab + "}\n\n"
        
        code += tab + "func matchingMethods<T>(_ stub: \(className)Stub<T>) -> [Any] {\n"
        code += tab + tab + "let callsToMethod = methodCalls.filter { object in\n"
        code += tab + tab + tab + "if let theMethod = object as? \(className)Stub<T> {\n"
        code += tab + tab + tab + tab + "return theMethod == stub\n"
        code += tab + tab + tab + "}\n"
        code += tab + tab + tab + "return false\n"
        code += tab + tab + "}\n"
        code += tab + tab + "return callsToMethod\n"
        code += tab + "}\n\n"
        
        code += tab + "class func matchingMethods<T>(_ stub: \(className)Stub<T>) -> [Any] {\n"
        code += tab + tab + "let callsToMethod = classMethodCalls.filter { object in\n"
        code += tab + tab + tab + "if let theMethod = object as? \(className)Stub<T> {\n"
        code += tab + tab + tab + tab + "return theMethod == stub\n"
        code += tab + tab + tab + "}\n"
        code += tab + tab + tab + "return false\n"
        code += tab + tab + "}\n"
        code += tab + tab + "return callsToMethod\n"
        code += tab + "}\n\n"

        code += tab + "func didCall<T>(method: \(className)Stub<T>) -> Bool {\n"
        code += tab + tab + "return matchingMethods(method).count > 0\n"
        code += tab + "}\n\n"
        
        code += tab + "class func didCall<T>(method: \(className)Stub<T>) -> Bool {\n"
        code += tab + tab + "return matchingMethods(method).count > 0\n"
        code += tab + "}\n\n"
        
        return code
    }
}
