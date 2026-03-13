import Foundation

struct GlyphEntry: Identifiable, Hashable {
    let codepoint: UInt32       // e.g. 0x2192
    let character: String       // the rendered character (may be multi-scalar)
    let germanName: String      // "nach rechts weisender Pfeil"
    let category: GlyphCategory

    var id: UInt32 { codepoint }

    /// "U+2192"
    var unicodeLabel: String { String(format: "U+%04X", codepoint) }
}
