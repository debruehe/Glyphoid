import Foundation
import Combine
import AppKit
import Carbon

/// Central ObservableObject. Injected as environment object into all views.
/// Coordinates services and drives the UI.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Services (internal, not exposed to views directly)
    let fontService: FontService
    let nameService: GlyphNameService
    let svgExporter: SVGExporter
    let clipboardService: ClipboardService
    let favoritesStore: FavoritesStore
    let windowStateStore: WindowStateStore
    let focusTracker: AppFocusTracker
    let windowManager: WindowManager

    // MARK: - Published state

    /// All glyphs for the current font, unfiltered
    @Published private(set) var allGlyphs: [GlyphEntry] = []

    /// Glyphs shown in the grid (filtered by search + category)
    @Published private(set) var filteredGlyphs: [GlyphEntry] = []

    /// Favorites that match the current filter (shown at top).
    @Published private(set) var filteredFavorites: [GlyphEntry] = []

    /// Codepoints of favorites that are NOT in the current font (shown greyed out).
    @Published private(set) var unavailableFavoriteCPs: Set<UInt32> = []

    /// Currently selected glyph (single-click or double-click)
    @Published var selectedGlyph: GlyphEntry?

    /// Search query string
    @Published var searchQuery: String = "" {
        didSet { applyFilters() }
    }

    /// Toast/status message for brief feedback (e.g. "Zeichen kopiert")
    @Published var toastMessage: String?

    /// Whether to show accessibility permission sheet
    @Published var showPermissionSheet: Bool = false

    /// Whether to show the About dialog
    @Published var showAboutDialog: Bool = false

    /// Updated by GlyphGridView via a GeometryReader so navigation uses the real grid width.
    var gridWidth: Double? = nil

    enum NavigationDirection { case left, right, up, down }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        let nameService = GlyphNameService()
        let fontService = FontService(nameService: nameService)
        self.nameService = nameService
        self.fontService = fontService
        self.svgExporter = SVGExporter()
        self.clipboardService = ClipboardService()
        self.favoritesStore = FavoritesStore()
        self.windowStateStore = WindowStateStore()
        self.focusTracker = AppFocusTracker()
        self.windowManager = WindowManager()

        // Wire up font/style/category changes → reload glyphs
        Publishers.CombineLatest3(
            windowStateStore.$selectedFontFamily,
            windowStateStore.$selectedStyle,
            windowStateStore.$selectedCategory
        )
        .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _ in
            self?.reloadGlyphs()
        }
        .store(in: &cancellables)

        // Wire favorites changes → re-apply filters
        favoritesStore.$favorites
            .sink { [weak self] _ in self?.applyFilters() }
            .store(in: &cancellables)

        // Sync isPinned to WindowManager
        windowStateStore.$isPinned
            .sink { [weak self] pinned in self?.windowManager.isPinned = pinned }
            .store(in: &cancellables)

        // Forward all windowStateStore changes (incl. cellSize) to our own objectWillChange
        // so views that read windowStateStore properties re-render correctly.
        windowStateStore.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        reloadGlyphs()
    }

    // MARK: - Actions

    func selectGlyph(_ glyph: GlyphEntry) {
        selectedGlyph = glyph
    }

    func insertGlyph(_ glyph: GlyphEntry) {
        selectGlyph(glyph)

        // Check permission first
        if !clipboardService.hasAccessibilityPermission {
            if !clipboardService.hasShownPermissionDialog {
                showPermissionSheet = true
                clipboardService.markPermissionDialogShown()
            }
            // Fallback: copy plain text to clipboard
            writeToClipboard(glyph.character)
            showToast("Zeichen in Zwischenablage kopiert")
            return
        }

        Task {
            let result = await clipboardService.insertCharacter(glyph.character,
                                                                into: focusTracker.lastActiveApp)
            switch result {
            case .inserted:
                break // success, no toast needed
            case .copiedOnly(let reason):
                showToast("Zeichen in Zwischenablage kopiert – \(reason)")
            }
        }
    }

    /// Async wrapper for call sites that prefer await (e.g. GlyphGridView onDoubleTap).
    func insertGlyphAsync(_ glyph: GlyphEntry) async {
        insertGlyph(glyph)
    }

    func copyVectorSVG(for glyph: GlyphEntry) {
        let family = windowStateStore.selectedFontFamily
        let style  = windowStateStore.selectedStyle
        if let svg = svgExporter.vectorSVG(character: glyph.character,
                                            fontFamily: family, style: style) {
            clipboardService.copySVGVector(svg)
            showToast("Vektor-SVG kopiert")
        } else {
            // Fallback to text SVG
            let svg = svgExporter.textSVG(character: glyph.character,
                                           fontFamily: family, style: style)
            clipboardService.copySVGText(svg)
            showToast("Text-SVG kopiert (Vektor nicht verfügbar)")
        }
    }

    func copyTextSVG(for glyph: GlyphEntry) {
        let family = windowStateStore.selectedFontFamily
        let style  = windowStateStore.selectedStyle
        let svg = svgExporter.textSVG(character: glyph.character,
                                       fontFamily: family, style: style)
        clipboardService.copySVGText(svg)
        showToast("Text-SVG kopiert")
    }

    func toggleFavorite(_ glyph: GlyphEntry) {
        favoritesStore.toggle(glyph.codepoint)
    }

    func navigateGrid(direction: NavigationDirection) {
        let allVisible = filteredFavorites + filteredGlyphs
        guard !allVisible.isEmpty else { return }

        if let current = selectedGlyph,
           let idx = allVisible.firstIndex(where: { $0.id == current.id }) {
            let cellTotal = windowStateStore.cellSize + 4
            let cols = max(1, Int((gridWidth ?? 340) / cellTotal))
            let newIdx: Int
            switch direction {
            case .left:  newIdx = max(0, idx - 1)
            case .right: newIdx = min(allVisible.count - 1, idx + 1)
            case .up:    newIdx = max(0, idx - cols)
            case .down:  newIdx = min(allVisible.count - 1, idx + cols)
            }
            selectedGlyph = allVisible[newIdx]
        } else {
            selectedGlyph = allVisible.first
        }
    }

    func persistState() {
        windowStateStore.persist()
    }

    // MARK: - Private

    private func reloadGlyphs() {
        let family = windowStateStore.selectedFontFamily
        let style  = windowStateStore.selectedStyle
        allGlyphs = fontService.glyphs(family: family, style: style)
        applyFilters()
    }

    private func applyFilters() {
        let query    = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        let category = windowStateStore.selectedCategory

        let filtered = allGlyphs.filter { matches(glyph: $0, query: query, category: category) }

        let favCPs = Set(favoritesStore.favorites)
        var favGlyphs: [GlyphEntry] = []
        var unavailableCPs: Set<UInt32> = []

        for cp in favoritesStore.favorites {
            if let g = allGlyphs.first(where: { $0.codepoint == cp }) {
                if matches(glyph: g, query: query, category: category) {
                    favGlyphs.append(g)
                }
            } else {
                let stub = GlyphEntry(
                    codepoint: cp,
                    character: Unicode.Scalar(cp).map(String.init) ?? "?",
                    germanName: nameService.germanName(for: cp),
                    category: nameService.category(for: cp)
                )
                // Unavailable favorites follow the same filter rules as available ones
                if matches(glyph: stub, query: query, category: category) {
                    favGlyphs.append(stub)
                    unavailableCPs.insert(cp)
                }
            }
        }

        filteredFavorites = favGlyphs
        unavailableFavoriteCPs = unavailableCPs
        filteredGlyphs = filtered.filter { !favCPs.contains($0.codepoint) }
    }

    private func matches(glyph: GlyphEntry, query: String, category: GlyphCategory) -> Bool {
        if category != .all && glyph.category != category { return false }
        guard !query.isEmpty else { return true }
        let name = glyph.germanName.lowercased()
        let char = glyph.character.lowercased()
        let cp   = String(format: "%x", glyph.codepoint)
        let cat  = glyph.category.rawValue.lowercased()
        return name.contains(query) || char == query ||
               cp.contains(query) || cat.contains(query)
    }

    private func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.toastMessage == message { self?.toastMessage = nil }
        }
    }

    private func writeToClipboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
