import XCTest
@testable import Glyphoid

final class GlyphNameServiceTests: XCTestCase {

    var service: GlyphNameService!

    override func setUp() {
        super.setUp()
        service = GlyphNameService()
    }

    func testRightArrowHasGermanName() {
        let name = service.germanName(for: 0x2192)
        XCTAssertFalse(name.isEmpty)
        // CLDR name contains direction/arrow concept
        let lower = name.lowercased()
        XCTAssertTrue(lower.contains("pfeil") || lower.contains("rechts") || lower.contains("pfeil"),
                      "Expected German arrow name, got: \(name)")
    }

    func testRightArrowCategory() {
        let cat = service.category(for: 0x2192)
        XCTAssertEqual(cat, .arrows)
    }

    func testEuroSignCategory() {
        let cat = service.category(for: 0x20AC) // €
        XCTAssertEqual(cat, .currency)
    }

    func testUnknownCodepointFallsBack() {
        let name = service.germanName(for: 0xE001) // private use
        XCTAssertFalse(name.isEmpty, "Should return fallback, not empty string")
    }

    func testCLDRVersion() {
        XCTAssertFalse(service.cldrVersion.isEmpty)
    }
}
