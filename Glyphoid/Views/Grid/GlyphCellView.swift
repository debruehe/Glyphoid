import SwiftUI

struct GlyphCellView: View {
    let glyph: GlyphEntry
    let fontFamily: String
    let cellSize: Double
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void

    @State private var isHovered = false
    @State private var lastTapDate: Date = .distantPast

    var body: some View {
        Text(glyph.character)
            .font(.custom(fontFamily, size: cellSize * 0.6))
            .foregroundColor(.primary)
            .frame(width: cellSize, height: cellSize)
            .background(cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .onHover { isHovered = $0 }
            .onTapGesture {
                let now = Date()
                if now.timeIntervalSince(lastTapDate) < 0.35 {
                    onDoubleTap()
                } else {
                    onTap()
                }
                lastTapDate = now
            }
            .help("\(glyph.germanName) · \(glyph.unicodeLabel)")
    }

    private var cellBackground: Color {
        if isSelected { return Color.accentColor.opacity(0.2) }
        if isHovered  { return Color(.selectedContentBackgroundColor).opacity(0.4) }
        return Color(.controlBackgroundColor)
    }
}
