import SwiftUI

struct AccessibilityPermissionView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.circle")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("Berechtigung benötigt")
                .font(.headline)

            Text("""
                Glyphoid benötigt die Berechtigung "Bedienungshilfen", \
                um Zeichen direkt in andere Apps einzufügen.

                Ohne diese Berechtigung wird das Zeichen nur in die \
                Zwischenablage kopiert — du kannst es dann manuell einfügen (⌘V).
                """)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button("Später") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Systemeinstellungen öffnen") {
                    state.clipboardService.openAccessibilitySettings()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}
