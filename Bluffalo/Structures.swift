import Foundation

enum MethodKind: String {
    case Instance = "source.lang.swift.decl.function.method.instance"
    case Class = "source.lang.swift.decl.function.method.class"
    case Static = "source.lang.swift.decl.function.method.static"
    case InstanceVar = "source.lang.swift.decl.var.instance"
    case Call = "source.lang.swift.expr.call"
    case StaticVar = "source.lang.swift.decl.var.static"
}

enum MethodAccessibility: String {
    case Internal = "source.lang.swift.accessibility.internal"
    case Private = "source.lang.swift.accessibility.private"
    case Fileprivate = "source.lang.swift.accessibility.fileprivate"
    case Public = "source.lang.swift.accessibility.public"
    case Open = "source.lang.swift.accessibility.open"
}

enum ClassKind: String {
    case ClassKind = "source.lang.swift.decl.class"
    case ProtocolKind = "source.lang.swift.decl.protocol"
    case StructKind = "source.lang.swift.decl.struct"
    case Unknown
}

// FIXME: Rename to MethodStruct to be consistent with naming? 
struct Method {
    let name: String
    let nameWithExternalNames: String
    let kind: MethodKind
    let accessibility: MethodAccessibility
    let argumentNames: [String]
    let externalArgumentNames: [String]
    let argumentTypes: [String]
    let returnType: String?
}

struct ClassStruct {
    let classKind: ClassKind
    let className: String
    
    private var _methods: [Method]?
    internal var methods: [Method] {
        return _methods ?? []
    }
    
    internal var enumName: String {
        return "\(className)Method"
    }
    
    init(classKind: ClassKind, className: String, methods: [Method]) {
        self.classKind = classKind
        self.className = className
        self._methods = onlyRealMethods(methods: methods)
    }
    
    private func onlyRealMethods(methods: [Method]) -> [Method] {
        return methods.filter { (method: Method) -> Bool in
            if method.name.contains("init(") {
                return false
            }
            
            return true
        }
    }
}
