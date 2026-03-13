import SwiftUI

struct CategoryFilterView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionLabel("FILTER")
            ForEach(GlyphCategory.allCases) { category in
                Button(action: { state.windowStateStore.selectedCategory = category }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(state.windowStateStore.selectedCategory == category
                                  ? Color.accentColor : Color.clear)
                            .frame(width: 5, height: 5)
                        Text(category.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(
                                state.windowStateStore.selectedCategory == category
                                ? .primary : .secondary
                            )
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        state.windowStateStore.selectedCategory == category
                        ? Color.accentColor.opacity(0.12) : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
