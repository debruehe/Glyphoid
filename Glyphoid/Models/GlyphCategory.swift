import Foundation

enum GlyphCategory: String, CaseIterable, Codable, Identifiable {
    case all         = "Alle"
    case arrows      = "Pfeile"
    case letters     = "Buchstaben"
    case currency    = "Währung"
    case math        = "Mathematik"
    case punctuation = "Satzzeichen"
    case other       = "Sonstiges"

    var id: String { rawValue }

    /// The key used in glyph-categories.json
    var jsonKey: String {
        switch self {
        case .all:         return "all"
        case .arrows:      return "arrows"
        case .letters:     return "letters"
        case .currency:    return "currency"
        case .math:        return "math"
        case .punctuation: return "punctuation"
        case .other:       return "other"
        }
    }
}
