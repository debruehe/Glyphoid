import SwiftUI

struct GlyphGridView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        let cellSize   = state.windowStateStore.cellSize
        let fontFamily = state.windowStateStore.selectedFontFamily
        let columns    = [GridItem(.adaptive(minimum: cellSize, maximum: cellSize), spacing: 4)]

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    Color.clear.frame(height: 0).id("glyphScrollTop")

                    if !state.recentGlyphs.isEmpty {
                        recentsSectionHeader

                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(state.recentGlyphs) { glyph in
                                GlyphCellView(
                                    glyph: glyph,
                                    fontFamily: fontFamily,
                                    cellSize: cellSize,
                                    isSelected: state.selectedGlyph?.id == glyph.id,
                                    onTap: { state.selectGlyph(glyph) },
                                    onDoubleTap: { Task { await state.insertGlyphAsync(glyph) } }
                                )
                            }
                        }
                        .padding(.horizontal, 8)

                        Divider()
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                    }

                    if state.filteredGlyphs.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(state.filteredGlyphs) { glyph in
                                GlyphCellView(
                                    glyph: glyph,
                                    fontFamily: fontFamily,
                                    cellSize: cellSize,
                                    isSelected: state.selectedGlyph?.id == glyph.id,
                                    onTap: { state.selectGlyph(glyph) },
                                    onDoubleTap: { state.insertGlyph(glyph) }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .id("topAnchor")
                    }

                    Spacer(minLength: 16)
                }
                .padding(.top, 8)
            }
            .onChange(of: state.windowStateStore.selectedFontFamily) { _ in resetScroll(proxy: proxy) }
            .onChange(of: state.windowStateStore.selectedCategory)   { _ in resetScroll(proxy: proxy) }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { state.gridWidth = geo.size.width }
                    .onChange(of: geo.size.width) { state.gridWidth = $0 }
            }
        )
    }

    private var recentsSectionHeader: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text("Zuletzt verwendet")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { state.clearRecents() }) {
                Text("Alle entfernen")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 60)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Keine Glyphen gefunden")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
    }

    private func resetScroll(proxy: ScrollViewProxy) {
        proxy.scrollTo("glyphScrollTop", anchor: .top)
    }
}
