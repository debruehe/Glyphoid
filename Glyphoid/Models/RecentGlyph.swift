import Foundation

struct RecentGlyph: Identifiable, Hashable {
    let codepoint: UInt32
    let character: String
    let germanName: String
    let category: GlyphCategory

    var id: UInt32 { codepoint }
    var unicodeLabel: String { String(format: "U+%04X", codepoint) }
}

// MARK: - Codable
// Custom implementation: encodes `category` via jsonKey ("arrows", "letters", …)
// because GlyphCategory's raw value is a German display string, not the JSON key.
extension RecentGlyph: Codable {
    private enum CodingKeys: String, CodingKey {
        case codepoint, character, germanName, category
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        codepoint  = try c.decode(UInt32.self,  forKey: .codepoint)
        character  = try c.decode(String.self,  forKey: .character)
        germanName = try c.decode(String.self,  forKey: .germanName)
        let key    = try c.decode(String.self,  forKey: .category)
        category   = GlyphCategory.allCases.first { $0.jsonKey == key } ?? .other
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(codepoint,          forKey: .codepoint)
        try c.encode(character,          forKey: .character)
        try c.encode(germanName,         forKey: .germanName)
        try c.encode(category.jsonKey,   forKey: .category)
    }
}
