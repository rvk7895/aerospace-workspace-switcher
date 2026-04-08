#if canImport(XCTest)
import XCTest
@testable import WorkspaceSwitcherCore

final class PlaceholderTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }
}
#elseif canImport(Testing)
import Testing
@testable import WorkspaceSwitcherCore

@Test func placeholder() {
    #expect(true)
}
#else
@testable import WorkspaceSwitcherCore
// No test framework available; this file compiles as a build-validation placeholder.
#endif
