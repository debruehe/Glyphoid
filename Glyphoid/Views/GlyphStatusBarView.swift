import SwiftUI

struct GlyphStatusBarView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        HStack(spacing: 0) {
            if let glyph = state.selectedGlyph {
                VStack(alignment: .leading, spacing: 1) {
                    Text(glyph.germanName)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                    Text(glyph.unicodeLabel)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)

                Spacer()

                HStack(spacing: 8) {
                    shortcutHint("⌘C", label: "Vektor-SVG")
                    shortcutHint("⌘⇧C", label: "Text-SVG")
                    shortcutHint("↩︎↩︎", label: "Einfügen")
                }
                .padding(.trailing, 10)
            } else {
                Text("Glyphe auswählen…")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                Spacer()
            }

            if let message = state.toastMessage {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
                    .padding(.trailing, 10)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .frame(height: 36)
        .background(Color(.windowBackgroundColor).opacity(0.8))
        .overlay(Divider(), alignment: .top)
    }

    private func shortcutHint(_ keys: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(keys)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}
