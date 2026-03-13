import AppKit
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

    // Window frame persistence keys
    private let frameXKey      = "windowFrameX"
    private let frameYKey      = "windowFrameY"
    private let frameWidthKey  = "windowFrameWidth"
    private let frameHeightKey = "windowFrameHeight"

    /// Save the current window frame to UserDefaults
    func saveWindowFrame(_ frame: NSRect) {
        defaults.set(Double(frame.origin.x), forKey: frameXKey)
        defaults.set(Double(frame.origin.y), forKey: frameYKey)
        defaults.set(Double(frame.width),    forKey: frameWidthKey)
        defaults.set(Double(frame.height),   forKey: frameHeightKey)
    }

    /// Load the previously saved window frame, or nil if not set
    func loadWindowFrame() -> NSRect? {
        let w = defaults.double(forKey: frameWidthKey)
        let h = defaults.double(forKey: frameHeightKey)
        guard w >= 480, h >= 480 else { return nil }  // sanity check
        let x = defaults.double(forKey: frameXKey)
        let y = defaults.double(forKey: frameYKey)
        return NSRect(x: x, y: y, width: w, height: h)
    }
}

private extension Double {
    func clamped(min: Double, max: Double, default defaultValue: Double) -> Double {
        if self == 0 { return defaultValue }
        return Swift.min(max, Swift.max(min, self))
    }
}
