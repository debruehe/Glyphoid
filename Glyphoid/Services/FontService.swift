import Foundation
import AppKit
import CoreText

/// Lists installed font families and enumerates all glyphs supported by a font.
final class FontService {

    private let nameService: GlyphNameService

    /// All installed font families, sorted alphabetically.
    private(set) var availableFamilies: [FontFamily]

    init(nameService: GlyphNameService) {
        self.nameService = nameService
        self.availableFamilies = Self.loadFamilies()
    }

    // MARK: - Glyph enumeration

    /// Returns all GlyphEntry values for the given family + style.
    /// Enumerates the font's character set via CoreText.
    func glyphs(family: String, style: String) -> [GlyphEntry] {
        guard let nsFont = NSFont(name: fontName(family: family, style: style),
                                  size: 12) else { return [] }
        let ctFont = nsFont as CTFont
        guard let charSet = CTFontCopyCharacterSet(ctFont) as? CharacterSet else { return [] }

        var entries: [GlyphEntry] = []
        // Iterate all Unicode planes 0..16
        for plane in 0..<17 {
            for page in 0..<256 {
                for offset in 0..<256 {
                    let scalar = UInt32(plane * 0x10000 + page * 0x100 + offset)
                    guard scalar <= 0x10FFFF,
                          !(0xD800...0xDFFF).contains(scalar), // skip surrogates
                          let unicodeScalar = Unicode.Scalar(scalar),
                          charSet.contains(unicodeScalar)
                    else { continue }

                    let entry = GlyphEntry(
                        codepoint: scalar,
                        character: String(unicodeScalar),
                        germanName: nameService.germanName(for: scalar),
                        category: nameService.category(for: scalar)
                    )
                    entries.append(entry)
                }
            }
        }
        return entries
    }

    // MARK: - Styles for a family

    func styles(for family: String) -> [String] {
        availableFamilies.first { $0.name == family }?.styles ?? []
    }

    // MARK: - Private helpers

    func fontName(family: String, style: String) -> String {
        // NSFontManager returns members as [postscript-name, style-name, weight, traits]
        guard let members = NSFontManager.shared.availableMembers(ofFontFamily: family)
        else { return family }
        for member in members {
            guard member.count >= 2,
                  let styleName = member[1] as? String,
                  styleName == style,
                  let psName = member[0] as? String
            else { continue }
            return psName
        }
        return family
    }

    private static func loadFamilies() -> [FontFamily] {
        NSFontManager.shared.availableFontFamilies.compactMap { family -> FontFamily? in
            guard let members = NSFontManager.shared.availableMembers(ofFontFamily: family)
            else { return nil }
            let styles = members.compactMap { member -> String? in
                guard member.count >= 2 else { return nil }
                return member[1] as? String
            }
            return FontFamily(name: family, styles: styles)
        }
        .sorted { $0.name < $1.name }
    }
}
