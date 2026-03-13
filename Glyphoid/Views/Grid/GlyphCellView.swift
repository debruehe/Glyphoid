import SwiftUI

struct GlyphCellView: View {
    let glyph: GlyphEntry
    let fontFamily: String
    let cellSize: Double
    let isSelected: Bool
    let isFavorite: Bool
    let isUnavailable: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onFavoriteToggle: () -> Void

    @State private var isHovered = false
    @State private var lastTapDate: Date = .distantPast

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(isUnavailable ? "?" : glyph.character)
                .font(.custom(
                    isUnavailable ? ".AppleSystemUIFont" : fontFamily,
                    size: cellSize * 0.6
                ))
                .foregroundColor(isUnavailable ? .secondary.opacity(0.4) : .primary)
                .frame(width: cellSize, height: cellSize)
                .background(cellBackground)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear,
                                      lineWidth: 1.5)
                )

            if !isUnavailable && (isHovered || isFavorite) {
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isFavorite ? .yellow : .secondary)
                        .padding(3)
                }
                .buttonStyle(.plain)
                .offset(x: -1, y: 1)
            }

            if isUnavailable {
                Image(systemName: "slash.circle")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(2)
                    .offset(x: -1, y: 1)
            }
        }
        .onHover { isHovered = $0 }
        .onTapGesture {
            guard !isUnavailable else { return }
            let now = Date()
            if now.timeIntervalSince(lastTapDate) < 0.35 {
                onDoubleTap()
            } else {
                onTap()
            }
            lastTapDate = now
        }
        .help(isUnavailable
              ? "\(glyph.germanName) – nicht in dieser Schrift"
              : "\(glyph.germanName) · \(glyph.unicodeLabel)")
    }

    private var cellBackground: Color {
        if isUnavailable { return Color(.windowBackgroundColor).opacity(0.3) }
        if isSelected    { return Color.accentColor.opacity(0.2) }
        if isHovered     { return Color(.selectedContentBackgroundColor).opacity(0.4) }
        return Color(.controlBackgroundColor)
    }
}
