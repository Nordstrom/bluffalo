import XCTest

@testable import Bluffalo

class GeneratorAppTests: XCTestCase {
    
    var subject: GeneratorApp!

    override func setUp() {
        super.setUp()
        subject = GeneratorApp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testCanInstantiateAppClass() {
        XCTAssertNotNil(subject)
    }
}
