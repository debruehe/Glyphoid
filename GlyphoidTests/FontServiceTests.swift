import XCTest
@testable import Glyphoid

final class FontServiceTests: XCTestCase {

    var service: FontService!
    var nameService: GlyphNameService!

    override func setUp() {
        super.setUp()
        nameService = GlyphNameService()
        service = FontService(nameService: nameService)
    }

    func testAvailableFamiliesNotEmpty() {
        XCTAssertFalse(service.availableFamilies.isEmpty)
    }

    func testHelveticaNeueExists() {
        let helvetica = service.availableFamilies.first { $0.name == "Helvetica Neue" }
        XCTAssertNotNil(helvetica)
    }

    func testHelveticaNeueHasStyles() {
        let helvetica = service.availableFamilies.first { $0.name == "Helvetica Neue" }!
        XCTAssertFalse(helvetica.styles.isEmpty)
    }

    func testGlyphsForHelveticaNeuAreNotEmpty() {
        let glyphs = service.glyphs(family: "Helvetica Neue", style: "Regular")
        XCTAssertFalse(glyphs.isEmpty)
    }

    func testGlyphsContainBasicLatin() {
        let glyphs = service.glyphs(family: "Helvetica Neue", style: "Regular")
        let codepoints = Set(glyphs.map(\.codepoint))
        XCTAssertTrue(codepoints.contains(0x0041)) // A
        XCTAssertTrue(codepoints.contains(0x0061)) // a
    }

    func testGlyphsHaveCategoryAssigned() {
        let glyphs = service.glyphs(family: "Helvetica Neue", style: "Regular")
        XCTAssertTrue(glyphs.allSatisfy { GlyphCategory.allCases.contains($0.category) })
    }
}
