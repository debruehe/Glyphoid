import XCTest
@testable import Glyphoid

final class FavoritesStoreTests: XCTestCase {

    var store: FavoritesStore!
    let testSuite = "com.glyphoid.tests.favorites"

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: testSuite)!
        defaults.removePersistentDomain(forName: testSuite)
        store = FavoritesStore(defaults: defaults)
    }

    func testInitiallyEmpty() {
        XCTAssertTrue(store.favorites.isEmpty)
    }

    func testAddFavorite() {
        store.add(0x2192)
        XCTAssertTrue(store.isFavorite(0x2192))
    }

    func testRemoveFavorite() {
        store.add(0x2192)
        store.remove(0x2192)
        XCTAssertFalse(store.isFavorite(0x2192))
    }

    func testToggle() {
        store.toggle(0x2192)
        XCTAssertTrue(store.isFavorite(0x2192))
        store.toggle(0x2192)
        XCTAssertFalse(store.isFavorite(0x2192))
    }

    func testPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: testSuite)!
        store.add(0x2665)
        let store2 = FavoritesStore(defaults: defaults)
        XCTAssertTrue(store2.isFavorite(0x2665))
    }

    func testOrderIsPreserved() {
        store.add(0x0041)
        store.add(0x2192)
        store.add(0x20AC)
        XCTAssertEqual(store.favorites, [0x0041, 0x2192, 0x20AC])
    }
}
