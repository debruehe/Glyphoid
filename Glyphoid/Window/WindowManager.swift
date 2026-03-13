import AppKit
import Combine

/// Controls whether the main window floats above all other windows (pinned)
/// or behaves as a normal window.
final class WindowManager: ObservableObject {

    @Published var isPinned: Bool = false {
        didSet { applyLevel() }
    }

    private weak var window: NSWindow?

    func configure(window: NSWindow, isPinned: Bool) {
        self.window = window
        self.isPinned = isPinned
    }

    func toggle() {
        isPinned.toggle()
    }

    // MARK: - Private

    private func applyLevel() {
        guard let window else { return }
        if isPinned {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            window.level = .normal
            window.collectionBehavior = []
        }
    }
}
