import SwiftUI

struct FontPickerView: View {
    @EnvironmentObject var state: AppState
    @State private var searchText = ""

    private var filteredFamilies: [FontFamily] {
        if searchText.isEmpty { return state.fontService.availableFamilies }
        return state.fontService.availableFamilies
            .filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("SCHRIFT")

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
}
