import Foundation
import AppKit
import CoreText
import CoreGraphics

/// Exports a glyph as SVG (vector path or text element).
final class SVGExporter {

    // MARK: - Public API

    /// Returns an SVG string with the real vector outline of the glyph,
    /// or nil if the glyph cannot be rendered (e.g. space, control character).
    func vectorSVG(character: String, fontFamily: String, style: String) -> String? {
        guard let cgPath = glyphPath(character: character,
                                     fontFamily: fontFamily,
                                     style: style) else { return nil }

        // Get the natural bounding box of the glyph
        let bounds = cgPath.boundingBoxOfPath

        // Build a transform that maps the glyph path into a 1000×1000 viewBox.
        // Font coordinates have y-axis pointing up; SVG has y pointing down.
        let scale: CGFloat
        if bounds.width > 0 || bounds.height > 0 {
            let s = max(bounds.width, bounds.height)
            scale = s > 0 ? 800 / s : 1
        } else {
            scale = 1
        }

        let tx = 100.0 - bounds.minX * scale
        let ty = 900.0 + bounds.minY * scale  // flip y

        var xform = CGAffineTransform(scaleX: scale, y: -scale)
            .translatedBy(x: bounds.minX == 0 ? 100 / scale : tx / scale,
                          y: bounds.minY == 0 ? -900 / scale : -ty / scale)

        guard let transformed = cgPath.copy(using: &xform) else { return nil }

        let pathData = svgPathData(from: transformed)
        guard !pathData.isEmpty else { return nil }

        return """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">
          <path d="\(pathData)" fill="#000000"/>
        </svg>
        """
    }

    /// Returns an SVG string with a `<text>` element.
    /// Always succeeds (falls back gracefully).
    func textSVG(character: String, fontFamily: String, style: String) -> String {
        let weight = svgFontWeight(style: style)
        let fontStyle = svgFontStyle(style: style)

        // Escape the character for XML
        let escaped = character
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")

        return """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">
          <text x="500" y="500" text-anchor="middle" dominant-baseline="central" font-family="\(fontFamily)" font-weight="\(weight)" font-style="\(fontStyle)" font-size="800" fill="#000000">\(escaped)</text>
        </svg>
        """
    }

    // MARK: - Private

    private func glyphPath(character: String, fontFamily: String, style: String) -> CGPath? {
        guard let nsFont = NSFont(name: postscriptName(family: fontFamily, style: style),
                                  size: 1000) else { return nil }
        let ctFont = nsFont as CTFont

        // Use UTF-16 code units for CTFontGetGlyphsForCharacters.
        // Supplementary-plane characters (> U+FFFF) need surrogate pairs.
        let utf16 = Array(character.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: utf16.count)
        var chars = utf16
        guard CTFontGetGlyphsForCharacters(ctFont, &chars, &glyphs, chars.count),
              glyphs[0] != 0 else { return nil }

        return CTFontCreatePathForGlyph(ctFont, glyphs[0], nil)
    }

    private func svgPathData(from path: CGPath) -> String {
        var commands: [String] = []
        path.applyWithBlock { elementPtr in
            let element = elementPtr.pointee
            let pts = element.points
            switch element.type {
            case .moveToPoint:
                commands.append(String(format: "M%.3f %.3f", pts[0].x, pts[0].y))
            case .addLineToPoint:
                commands.append(String(format: "L%.3f %.3f", pts[0].x, pts[0].y))
            case .addQuadCurveToPoint:
                commands.append(String(format: "Q%.3f %.3f %.3f %.3f",
                                       pts[0].x, pts[0].y, pts[1].x, pts[1].y))
            case .addCurveToPoint:
                commands.append(String(format: "C%.3f %.3f %.3f %.3f %.3f %.3f",
                                       pts[0].x, pts[0].y, pts[1].x, pts[1].y,
                                       pts[2].x, pts[2].y))
            case .closeSubpath:
                commands.append("Z")
            @unknown default:
                break
            }
        }
        return commands.joined(separator: " ")
    }

    private func postscriptName(family: String, style: String) -> String {
        guard let members = NSFontManager.shared.availableMembers(ofFontFamily: family)
        else { return family }
        for member in members {
            // member[0] = PostScript name, member[1] = style name, member[2] = weight, member[3] = traits
            guard member.count >= 4,
                  let styleName = member[1] as? String, styleName == style,
                  let psName = member[0] as? String else { continue }
            return psName
        }
        return family
    }

    private func svgFontWeight(style: String) -> String {
        let lower = style.lowercased()
        if lower.contains("bold") || lower.contains("heavy") || lower.contains("black") {
            return "bold"
        }
        if lower.contains("light") || lower.contains("thin") { return "300" }
        return "normal"
    }

    private func svgFontStyle(style: String) -> String {
        style.lowercased().contains("italic") || style.lowercased().contains("oblique")
            ? "italic" : "normal"
    }
}
