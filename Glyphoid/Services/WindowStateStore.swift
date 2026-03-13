import Foundation
import Combine

/// Persists window/session state between app launches via UserDefaults.
final class WindowStateStore: ObservableObject {

    @Published var selectedFontFamily: String
    @Published var selectedStyle: String
    @Published var cellSize: Double
    @Published var selectedCategory: GlyphCategory
    @Published var isPinned: Bool

    private let defaults: UserDefaults

    private enum Key {
        static let fontFamily = "glyphoid.fontFamily"
        static let fontStyle  = "glyphoid.fontStyle"
        static let cellSize   = "glyphoid.cellSize"
        static let category   = "glyphoid.category"
        static let isPinned   = "glyphoid.isPinned"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedFontFamily = defaults.string(forKey: Key.fontFamily) ?? "Helvetica Neue"
        selectedStyle      = defaults.string(forKey: Key.fontStyle)  ?? "Regular"
        cellSize           = defaults.double(forKey: Key.cellSize).clamped(min: 24, max: 96,
                                                                            default: 48)
        let rawCat = defaults.string(forKey: Key.category) ?? ""
        selectedCategory   = GlyphCategory.allCases.first { $0.jsonKey == rawCat } ?? .all
        isPinned           = defaults.bool(forKey: Key.isPinned)
    }

    /// Call this on app quit (wired in GlyphoidApp — Task 15).
    func persist() {
        defaults.set(selectedFontFamily,     forKey: Key.fontFamily)
        defaults.set(selectedStyle,          forKey: Key.fontStyle)
        defaults.set(cellSize,               forKey: Key.cellSize)
        defaults.set(selectedCategory.jsonKey, forKey: Key.category)
        defaults.set(isPinned,               forKey: Key.isPinned)
    }
}

private extension Double {
    func clamped(min: Double, max: Double, default defaultValue: Double) -> Double {
        if self == 0 { return defaultValue }
        return Swift.min(max, Swift.max(min, self))
    }
}
