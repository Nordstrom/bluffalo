import Foundation

//Enums
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


//Structures
struct Method {
    var name: String
    var nameWithExternalNames: String = ""
    var kind: MethodKind = .Instance
    var accessibility: MethodAccessibility = .Private
    var argumentNames: [String] = []
    var externalArgumentNames: [String] = []
    var argumentTypes: [String] = []
    var returnType: String?
}

struct ClassStruct {
    var classKind : ClassKind
    var className: String
    var methods: [Method] = []
}
