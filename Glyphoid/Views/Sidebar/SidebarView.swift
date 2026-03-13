import SwiftUI

struct SidebarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FontPickerView()
            SizeSliderView()
            Divider()
            CategoryFilterView()
            Spacer()
        }
        .padding(10)
        .frame(width: 140)
        .background(Color(.windowBackgroundColor).opacity(0.6))
    }
}

// Shared section label helper used across sidebar views
func sectionLabel(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 9, weight: .semibold))
        .foregroundColor(.secondary)
        .tracking(0.8)
}
