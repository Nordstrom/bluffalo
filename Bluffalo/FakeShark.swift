import Foundation
private func checkEquality(a: AnyObject, b: AnyObject) -> Bool {
    if let aString: String = a as? String,
        let bString: String = b as? String {
        return aString == bString
    }

    if let aDict: [String:String] = a as? [String:String],
        let bDict: [String:String] = b as? [String:String] {
        return aDict == bDict
    }

    //As other types of any objects are added we will need to add a way to compare them here
    return false
}

public enum SharkMethod: Equatable, Hashable {
    case eat_food(String)
    case eat()
    case returnsOptionalBool()
    case sharkinate()
    public var hashValue: Int {
        get {
            switch self {
            case .eat_food:
                return 0
            case .eat:
                return 1
            case .returnsOptionalBool:
                return 2
            case .sharkinate:
                return 3
            }
        }
    }
}

public func == (lhs: SharkMethod, rhs: SharkMethod) -> Bool {
    switch (lhs, rhs) {
    case (.eat_food(let a1), .eat_food(let b1)): return a1 == b1
    case (.eat(), .eat()): return true
    case (.returnsOptionalBool(), .returnsOptionalBool()): return true
    case (.sharkinate(), .sharkinate()): return true

    case (.eat_food, _): return false
    case (.eat, _): return false
    case (.returnsOptionalBool, _): return false
    case (.sharkinate, _): return false
    }
}
public func methodsMatching(lhs: SharkMethod, rhs: SharkMethod) -> Bool {
    switch (lhs, rhs) {
    case (.eat_food, .eat_food): return true
    case (.eat, .eat): return true
    case (.returnsOptionalBool, .returnsOptionalBool): return true
    case (.sharkinate, .sharkinate): return true

    case (.eat_food, _): return false
    case (.eat, _): return false
    case (.returnsOptionalBool, _): return false
    case (.sharkinate, _): return false
    }
}

class FakeShark: Shark {
    private var functionsAndArgumentsCalled: [SharkMethod] = []
    private static var classFunctionsAndArgumentsCalled: [SharkMethod] = []

    private var stubbedValues = [SharkMethod:Any]()

    func stub(method: SharkMethod, andReturn value: Any) {
        stubbedValues[method] = value
    }

    func functionsMatchingMethodTypeAndArguments(forMethod: SharkMethod) -> [SharkMethod] {
        return functionsAndArgumentsCalled.filter { (method: SharkMethod) -> Bool in
            return method == forMethod
        }
    }

    class func functionsMatchingMethodTypeAndArguments(forMethod: SharkMethod) -> [SharkMethod] {
        return classFunctionsAndArgumentsCalled.filter { (method: SharkMethod) -> Bool in
            return method == forMethod
        }
    }

    func functionsMatchingMethod(forMethod: SharkMethod) -> [SharkMethod] {
        return functionsAndArgumentsCalled.filter { (method: SharkMethod) -> Bool in
            return methodsMatching(lhs: method, rhs: forMethod)
        }
    }

    internal func didCall(method: SharkMethod) -> Bool {
        return functionsMatchingMethodTypeAndArguments(forMethod: method).count > 0
    }

    override func eat(food: String) -> Poop {
        functionsAndArgumentsCalled.append(SharkMethod.eat_food(food))
        return stubbedValues[.eat_food(food)] as! Poop
    }

    override func eat() -> Poop {
        functionsAndArgumentsCalled.append(SharkMethod.eat())
        return stubbedValues[.eat()] as! Poop
    }

    override func returnsOptionalBool() -> Bool? {
        functionsAndArgumentsCalled.append(SharkMethod.returnsOptionalBool())
        return stubbedValues[.returnsOptionalBool()] as? Bool
    }

    override class func sharkinate() {
        classFunctionsAndArgumentsCalled.append(SharkMethod.sharkinate())
    }
}
