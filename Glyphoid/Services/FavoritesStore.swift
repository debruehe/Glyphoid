import Foundation
import Combine

/// Persists the user's favorite glyph codepoints (stored as [UInt32]).
/// Order is insertion order. Published so views can observe changes.
final class FavoritesStore: ObservableObject {

    @Published private(set) var favorites: [UInt32] = []

    private let defaults: UserDefaults
    private let key = "glyphoid.favorites"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func isFavorite(_ codepoint: UInt32) -> Bool {
        favorites.contains(codepoint)
    }

    func add(_ codepoint: UInt32) {
        guard !isFavorite(codepoint) else { return }
        favorites.append(codepoint)
        save()
    }

    func remove(_ codepoint: UInt32) {
        favorites.removeAll { $0 == codepoint }
        save()
    }

    func toggle(_ codepoint: UInt32) {
        isFavorite(codepoint) ? remove(codepoint) : add(codepoint)
    }

    // MARK: - Private

    private func load() {
        // Store as hex strings to avoid any signed-integer cast ambiguity
        let raw = defaults.array(forKey: key) as? [String] ?? []
        favorites = raw.compactMap { UInt32($0, radix: 16) }
    }

    private func save() {
        defaults.set(favorites.map { String($0, radix: 16) }, forKey: key)
    }
}
