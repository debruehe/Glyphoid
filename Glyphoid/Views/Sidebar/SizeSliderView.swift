import SwiftUI

struct SizeSliderView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("GRÖSSE")
            HStack(spacing: 6) {
                Image(systemName: "textformat.size.smaller")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Slider(value: Binding(
                    get: { state.windowStateStore.cellSize },
                    set: { state.windowStateStore.cellSize = $0 }
                ), in: 24...96, step: 4)
                    .tint(.accentColor)
                Image(systemName: "textformat.size.larger")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}
