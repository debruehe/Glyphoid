import Foundation

/// Loads bundled CLDR German names and UCD category assignments.
/// Thread-safe after init (all data is read-only).
final class GlyphNameService {

    // { "2192": "nach rechts weisender Pfeil" }
    private let names: [String: String]
    // { "2192": "arrows" }
    private let categoryMap: [String: String]

    /// CLDR data version embedded in the JSON (key "_version"), empty if absent.
    let cldrVersion: String

    init(bundle: Bundle = .main) {
        func loadJSON(_ filename: String) -> [String: String] {
            guard let url = bundle.url(forResource: filename, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data)
            else {
                assertionFailure("Could not load \(filename).json from bundle")
                return [:]
            }
            return dict
        }

        let rawNames = loadJSON("cldr-de-names")
        self.cldrVersion = rawNames["_version"] ?? "bundled"
        // Remove metadata keys (start with "_")
        self.names = rawNames.filter { !$0.key.hasPrefix("_") }
        self.categoryMap = loadJSON("glyph-categories")
    }

    /// German name for a Unicode codepoint. Falls back to "U+XXXX" if unknown.
    func germanName(for codepoint: UInt32) -> String {
        let key = String(format: "%X", codepoint).uppercased()
        if let name = names[key], !name.isEmpty { return name }
        // Fallback: format as U+XXXX
        return String(format: "U+%04X", codepoint)
    }

    /// Glyphoid category for a Unicode codepoint.
    func category(for codepoint: UInt32) -> GlyphCategory {
        let key = String(format: "%X", codepoint).uppercased()
        guard let raw = categoryMap[key] else { return .other }
        return GlyphCategory.allCases.first { $0.jsonKey == raw } ?? .other
    }
}
