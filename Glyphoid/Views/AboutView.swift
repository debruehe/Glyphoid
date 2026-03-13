import SwiftUI

struct AboutView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "character.magnify")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Glyphoid")
                .font(.title2.bold())

            Text("Version \(appVersion)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                infoRow("CLDR-Version", state.nameService.cldrVersion)
                infoRow("Plattform", "macOS 14+")
            }

            Text("© 2026 — Alle Rechte vorbehalten")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Button("Schließen") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 280)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .monospaced))
        }
    }
}
