import SwiftUI

struct FontPickerView: View {
    @EnvironmentObject var state: AppState
    @State private var searchText = ""
    @FocusState private var isFamilyFocused: Bool

    private var filteredFamilies: [FontFamily] {
        if searchText.isEmpty { return state.fontService.availableFamilies }
        return state.fontService.availableFamilies
            .filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("SCHRIFT")

            ZStack {
                Menu {
                    TextField("Suchen…", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(4)
                    Divider()
                    ForEach(filteredFamilies) { family in
                        Button(family.name) {
                            state.windowStateStore.selectedFontFamily = family.name
                            state.windowStateStore.selectedStyle = family.styles.first ?? "Regular"
                            searchText = ""
                        }
                    }
                } label: {
                    HStack {
                        Text(state.windowStateStore.selectedFontFamily)
                            .font(.system(size: 11))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .menuStyle(.borderlessButton)
            }
            // .focusable() on the ZStack lets Tab navigation reach it.
            // .simultaneousGesture lets the Menu still open on click while also
            // programmatically taking focus so arrow keys work immediately after.
            .focusable()
            .focusEffectDisabled()
            .focused($isFamilyFocused)
            .simultaneousGesture(TapGesture().onEnded { isFamilyFocused = true })
            .onKeyPress(.upArrow)   { navigateFamily(by: -1); return .handled }
            .onKeyPress(.downArrow) { navigateFamily(by:  1); return .handled }
            .onChange(of: state.windowStateStore.selectedFontFamily) { _ in isFamilyFocused = true }
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(isFamilyFocused ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    .allowsHitTesting(false)
            )

            let styles = state.fontService.styles(for: state.windowStateStore.selectedFontFamily)
            if !styles.isEmpty {
                Menu {
                    ForEach(styles, id: \.self) { style in
                        Button(style) { state.windowStateStore.selectedStyle = style }
                    }
                } label: {
                    HStack {
                        Text(state.windowStateStore.selectedStyle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(.controlBackgroundColor).opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .menuStyle(.borderlessButton)
            }
        }
    }

    private func navigateFamily(by delta: Int) {
        let families = state.fontService.availableFamilies
        guard !families.isEmpty else { return }
        let current = state.windowStateStore.selectedFontFamily
        let idx = families.firstIndex(where: { $0.name == current }) ?? 0
        let newIdx = max(0, min(families.count - 1, idx + delta))
        let newFamily = families[newIdx]
        state.windowStateStore.selectedFontFamily = newFamily.name
        state.windowStateStore.selectedStyle = newFamily.styles.first ?? "Regular"
    }
}
