import XCTest
@testable import array_filler

class array_fillerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(array_filler().text, "Hello, World!")
    }


    static var allTests : [(String, (array_fillerTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
