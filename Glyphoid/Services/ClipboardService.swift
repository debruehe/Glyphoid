import Foundation
import AppKit
import Carbon

/// Handles all clipboard writes and character insertion into other apps.
final class ClipboardService {

    // MARK: - SVG Copy

    func copySVGVector(_ svg: String) {
        writeToClipboard(svg, type: .string)
    }

    func copySVGText(_ svg: String) {
        writeToClipboard(svg, type: .string)
    }

    // MARK: - Character insertion

    enum InsertResult {
        case inserted
        case copiedOnly(reason: String)
    }

    /// True if the accessibility permission dialog has been shown this session.
    private(set) var hasShownPermissionDialog: Bool = false

    /// Marks that the permission dialog has been shown this session.
    func markPermissionDialogShown() {
        hasShownPermissionDialog = true
    }

    /// Puts `character` in the clipboard then simulates Cmd+V in the target app.
    /// - Parameter targetApp: the app to paste into (nil = currently frontmost).
    /// - Returns: `.inserted` on success, `.copiedOnly` with reason on failure.
    @discardableResult
    func insertCharacter(_ character: String,
                         into targetApp: NSRunningApplication?) async -> InsertResult {
        // 1. Write plain text to clipboard
        writeToClipboard(character, type: .string)

        // 2. Check Accessibility permission
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        guard AXIsProcessTrustedWithOptions(options) else {
            return .copiedOnly(reason: "Keine Bedienungshilfen-Berechtigung")
        }

        // 3. Activate target app and wait for it to come to foreground
        if let app = targetApp {
            app.activate(options: .activateIgnoringOtherApps)
            try? await Task.sleep(for: .milliseconds(100))
        }

        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return .copiedOnly(reason: "CGEventSource konnte nicht erstellt werden")
        }

        // Key code 9 = V on US keyboard (layout-independent for Cmd+V)
        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
            let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        else {
            return .copiedOnly(reason: "CGEvent konnte nicht erstellt werden")
        }
        keyDown.flags = .maskCommand
        keyUp.flags   = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)

        return .inserted
    }

    // MARK: - Accessibility permission check

    /// Returns true if Accessibility is granted (no prompt shown).
    var hasAccessibilityPermission: Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings to the Accessibility pane.
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private

    private func writeToClipboard(_ string: String, type: NSPasteboard.PasteboardType) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: type)
    }
}
