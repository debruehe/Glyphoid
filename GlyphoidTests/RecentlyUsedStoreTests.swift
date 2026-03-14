import XCTest
@testable import Glyphoid

final class RecentlyUsedStoreTests: XCTestCase {

    var store: RecentlyUsedStore!
    let suite = "com.glyphoid.tests.recents"

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        store = RecentlyUsedStore(defaults: defaults)
    }

    // Helpers
    private func glyph(_ cp: UInt32, category: GlyphCategory = .other) -> GlyphEntry {
        GlyphEntry(codepoint: cp,
                   character: Unicode.Scalar(cp).map(String.init) ?? "?",
                   germanName: "Test \(cp)",
                   category: category)
    }

    func testInitiallyEmpty() {
        XCTAssertTrue(store.recents.isEmpty)
    }

    func testRecordAddsToTop() {
        store.record(glyph(0x2192))
        store.record(glyph(0x2665))
        XCTAssertEqual(store.recents[0].codepoint, 0x2665)
        XCTAssertEqual(store.recents[1].codepoint, 0x2192)
        XCTAssertEqual(store.recents.count, 2)
    }

    func testRecordDeduplicatesAndMovesToTop() {
        store.record(glyph(0x2192))
        store.record(glyph(0x2665))
        store.record(glyph(0x2192))  // already present → move to top
        XCTAssertEqual(store.recents[0].codepoint, 0x2192)
        XCTAssertEqual(store.recents[1].codepoint, 0x2665)
        XCTAssertEqual(store.recents.count, 2)
    }

    func testRecordCapsAt20() {
        for i: UInt32 in 0x41...0x59 {   // 25 glyphs
            store.record(glyph(i))
        }
        XCTAssertEqual(store.recents.count, 20)
        XCTAssertEqual(store.recents[0].codepoint, 0x59)   // most recent at top
        XCTAssertEqual(store.recents[19].codepoint, 0x46)  // oldest kept
    }

    func testClearAll() {
        store.record(glyph(0x2192))
        store.clearAll()
        XCTAssertTrue(store.recents.isEmpty)
    }

    func testPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: suite)!
        store.record(glyph(0x2192))
        let store2 = RecentlyUsedStore(defaults: defaults)
        XCTAssertEqual(store2.recents.first?.codepoint, 0x2192)
    }

    func testCategoryRoundTrips() {
        // Encodes via jsonKey ("arrows"), decodes back to .arrows
        let defaults = UserDefaults(suiteName: suite)!
        store.record(glyph(0x2192, category: .arrows))
        let store2 = RecentlyUsedStore(defaults: defaults)
        XCTAssertEqual(store2.recents.first?.category, .arrows)
    }

    func testOrderIsPreserved() {
        store.record(glyph(0x41))
        store.record(glyph(0x42))
        store.record(glyph(0x43))
        XCTAssertEqual(store.recents.map(\.codepoint), [0x43, 0x42, 0x41])
    }
}
