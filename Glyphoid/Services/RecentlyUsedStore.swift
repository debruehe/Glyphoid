import Foundation
import Combine

/// Tracks the last 20 glyphs the user inserted or copied.
/// Ordered most-recent-first. Published so views can observe changes.
final class RecentlyUsedStore: ObservableObject {

    @Published private(set) var recents: [RecentGlyph] = []

    private let defaults: UserDefaults
    private let key = "glyphoid.recentlyUsed"
    private let maxCount = 20

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    /// Snapshot `glyph`, move it to index 0, cap the list at 20, persist.
    func record(_ glyph: GlyphEntry) {
        let snap = RecentGlyph(codepoint: glyph.codepoint,
                               character: glyph.character,
                               germanName: glyph.germanName,
                               category: glyph.category)
        recents.removeAll { $0.codepoint == snap.codepoint }
        recents.insert(snap, at: 0)
        if recents.count > maxCount {
            recents.removeLast(recents.count - maxCount)
        }
        save()
    }

    func clearAll() {
        recents = []
        save()
    }

    // MARK: - Private

    private func load() {
        guard let data = defaults.data(forKey: key),
              let loaded = try? JSONDecoder().decode([RecentGlyph].self, from: data)
        else { return }
        recents = loaded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(recents) else { return }
        defaults.set(data, forKey: key)
    }
}
