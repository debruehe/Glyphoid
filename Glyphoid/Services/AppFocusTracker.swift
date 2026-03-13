import Foundation
import AppKit
import Combine

/// Tracks which application was active before Glyphoid received focus.
/// Used by ClipboardService to know where to simulate Cmd+V.
final class AppFocusTracker: ObservableObject {

    /// The last app that was frontmost (excluding Glyphoid itself).
    @Published private(set) var lastActiveApp: NSRunningApplication?

    private var observer: NSObjectProtocol?

    init() {
        // Observe whenever any application is about to lose active status
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                            as? NSRunningApplication,
                app.bundleIdentifier != Bundle.main.bundleIdentifier
            else { return }
            self?.lastActiveApp = app
        }
    }

    deinit {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }
}
