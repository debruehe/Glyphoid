import SwiftUI
import AppKit

@main
struct GlyphoidApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear { configureWindow(appState: appState) }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Über Glyphoid") {
                    appState.showAboutDialog = true
                }
            }
            CommandGroup(after: .appInfo) {
                Divider()
                Button(appState.windowStateStore.isPinned
                       ? "Fenster lösen" : "Fenster anheften") {
                    appState.windowManager.toggle()
                    appState.windowStateStore.isPinned = appState.windowManager.isPinned
                    appState.persistState()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}

private func configureWindow(appState: AppState) {
    guard let window = NSApp.windows.first else { return }

    // Minimum size
    window.minSize = NSSize(width: 480, height: 480)

    // Restore window frame
    if let frame = appState.windowStateStore.loadWindowFrame() {
        window.setFrame(frame, display: false)
    }

    // Restore pinned state
    appState.windowManager.configure(
        window: window,
        isPinned: appState.windowStateStore.isPinned
    )

    // Persist state on quit
    NotificationCenter.default.addObserver(
        forName: NSApplication.willTerminateNotification,
        object: nil, queue: .main
    ) { _ in
        if let window = NSApp.windows.first {
            appState.windowStateStore.saveWindowFrame(window.frame)
        }
        appState.persistState()
    }
}
