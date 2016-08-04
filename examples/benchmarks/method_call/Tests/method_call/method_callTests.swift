import XCTest
@testable import method_call

class method_callTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(method_call().text, "Hello, World!")
    }


    static var allTests : [(String, (method_callTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
