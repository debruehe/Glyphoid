# Recently Used Glyphs Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the broken favorites feature entirely and replace it with a "recently used" section that snapshots the last 20 glyphs the user inserted or copied, persists across restarts, and requires no font lookup at render time.

**Architecture:** A new `RecentlyUsedStore` (ObservableObject) stores `[RecentGlyph]` in UserDefaults as JSON. `AppState` owns the store, exposes `recentGlyphs: [GlyphEntry]` (converted from snapshots), and records a glyph on every insert/copy action. The view layer replaces the favorites section with a recents section; `GlyphCellView` is simplified by removing all favorites-specific parameters.

**Tech Stack:** Swift 5.9, SwiftUI, Combine, XCTest, UserDefaults (JSON encoding)

**Spec:** `docs/superpowers/specs/2026-03-14-recently-used-glyphs-design.md`

---

## Chunk 1: Data and service layer

### Task 1: Create `RecentGlyph` model

**Files:**
- Create: `Glyphoid/Models/RecentGlyph.swift`

`GlyphCategory` raw values are German display strings (`"Pfeile"` etc.), so synthesised `Codable` would encode the wrong value. `RecentGlyph` provides a custom `Codable` implementation that encodes `category` via `jsonKey` (`"arrows"` etc.) — the same English key used throughout the rest of the app.

- [ ] **Step 1: Create `Glyphoid/Models/RecentGlyph.swift`**

```swift
import Foundation

struct RecentGlyph: Identifiable, Hashable {
    let codepoint: UInt32
    let character: String
    let germanName: String
    let category: GlyphCategory

    var id: UInt32 { codepoint }
    var unicodeLabel: String { String(format: "U+%04X", codepoint) }
}

// MARK: - Codable
// Custom implementation: encodes `category` via jsonKey ("arrows", "letters", …)
// because GlyphCategory's raw value is a German display string, not the JSON key.
extension RecentGlyph: Codable {
    private enum CodingKeys: String, CodingKey {
        case codepoint, character, germanName, category
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        codepoint  = try c.decode(UInt32.self,  forKey: .codepoint)
        character  = try c.decode(String.self,  forKey: .character)
        germanName = try c.decode(String.self,  forKey: .germanName)
        let key    = try c.decode(String.self,  forKey: .category)
        category   = GlyphCategory.allCases.first { $0.jsonKey == key } ?? .other
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(codepoint,          forKey: .codepoint)
        try c.encode(character,          forKey: .character)
        try c.encode(germanName,         forKey: .germanName)
        try c.encode(category.jsonKey,   forKey: .category)
    }
}
```

- [ ] **Step 2: Build the project in Xcode to verify it compiles** (Product → Build, ⌘B)

---

### Task 2: Create `RecentlyUsedStore` with tests

**Files:**
- Create: `Glyphoid/Services/RecentlyUsedStore.swift`
- Create: `GlyphoidTests/RecentlyUsedStoreTests.swift`

- [ ] **Step 1: Write the tests first**

Create `GlyphoidTests/RecentlyUsedStoreTests.swift`:

```swift
import XCTest
@testable import Glyphoid

final class RecentlyUsedStoreTests: XCTestCase {

    var store: RecentlyUsedStore!
    let suite = "com.glyphoid.tests.recents"

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        store = RecentlyUsedStore(defaults: defaults)
    }

    // Helpers
    private func glyph(_ cp: UInt32, category: GlyphCategory = .other) -> GlyphEntry {
        GlyphEntry(codepoint: cp,
                   character: Unicode.Scalar(cp).map(String.init) ?? "?",
                   germanName: "Test \(cp)",
                   category: category)
    }

    func testInitiallyEmpty() {
        XCTAssertTrue(store.recents.isEmpty)
    }

    func testRecordAddsToTop() {
        store.record(glyph(0x2192))
        store.record(glyph(0x2665))
        XCTAssertEqual(store.recents[0].codepoint, 0x2665)
        XCTAssertEqual(store.recents[1].codepoint, 0x2192)
        XCTAssertEqual(store.recents.count, 2)
    }

    func testRecordDeduplicatesAndMovesToTop() {
        store.record(glyph(0x2192))
        store.record(glyph(0x2665))
        store.record(glyph(0x2192))  // already present → move to top
        XCTAssertEqual(store.recents[0].codepoint, 0x2192)
        XCTAssertEqual(store.recents[1].codepoint, 0x2665)
        XCTAssertEqual(store.recents.count, 2)
    }

    func testRecordCapsAt20() {
        for i: UInt32 in 0x41...0x59 {   // 25 glyphs
            store.record(glyph(i))
        }
        XCTAssertEqual(store.recents.count, 20)
        XCTAssertEqual(store.recents[0].codepoint, 0x59)   // most recent at top
        XCTAssertEqual(store.recents[19].codepoint, 0x46)  // oldest kept
    }

    func testClearAll() {
        store.record(glyph(0x2192))
        store.clearAll()
        XCTAssertTrue(store.recents.isEmpty)
    }

    func testPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: suite)!
        store.record(glyph(0x2192))
        let store2 = RecentlyUsedStore(defaults: defaults)
        XCTAssertEqual(store2.recents.first?.codepoint, 0x2192)
    }

    func testCategoryRoundTrips() {
        // Encodes via jsonKey ("arrows"), decodes back to .arrows
        let defaults = UserDefaults(suiteName: suite)!
        store.record(glyph(0x2192, category: .arrows))
        let store2 = RecentlyUsedStore(defaults: defaults)
        XCTAssertEqual(store2.recents.first?.category, .arrows)
    }

    func testOrderIsPreserved() {
        store.record(glyph(0x41))
        store.record(glyph(0x42))
        store.record(glyph(0x43))
        XCTAssertEqual(store.recents.map(\.codepoint), [0x43, 0x42, 0x41])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail** (Xcode: ⌘U → expect build error "RecentlyUsedStore not found")

- [ ] **Step 3: Create `Glyphoid/Services/RecentlyUsedStore.swift`**

```swift
import Foundation
import Combine

/// Tracks the last 20 glyphs the user inserted or copied.
/// Ordered most-recent-first. Published so views can observe changes.
final class RecentlyUsedStore: ObservableObject {

    @Published private(set) var recents: [RecentGlyph] = []

    private let defaults: UserDefaults
    private let key = "glyphoid.recentlyUsed"
    private let maxCount = 20

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    /// Snapshot `glyph`, move it to index 0, cap the list at 20, persist.
    func record(_ glyph: GlyphEntry) {
        let snap = RecentGlyph(codepoint: glyph.codepoint,
                               character: glyph.character,
                               germanName: glyph.germanName,
                               category: glyph.category)
        recents.removeAll { $0.codepoint == snap.codepoint }
        recents.insert(snap, at: 0)
        if recents.count > maxCount {
            recents.removeLast(recents.count - maxCount)
        }
        save()
    }

    func clearAll() {
        recents = []
        save()
    }

    // MARK: - Private

    private func load() {
        guard let data = defaults.data(forKey: key),
              let loaded = try? JSONDecoder().decode([RecentGlyph].self, from: data)
        else { return }
        recents = loaded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(recents) else { return }
        defaults.set(data, forKey: key)
    }
}
```

- [ ] **Step 4: Add `RecentlyUsedStoreTests.swift` to the test target in Xcode** (if not already added: drag file into GlyphoidTests group in the Project Navigator; verify target membership in File Inspector)

- [ ] **Step 5: Run tests (⌘U) — all `RecentlyUsedStoreTests` must pass**

- [ ] **Step 6: Commit**

```bash
git add Glyphoid/Models/RecentGlyph.swift \
        Glyphoid/Services/RecentlyUsedStore.swift \
        GlyphoidTests/RecentlyUsedStoreTests.swift
git commit -m "feat: add RecentGlyph model and RecentlyUsedStore with tests"
```

---

## Chunk 2: AppState refactor

### Task 3: Replace favorites with recently-used in `AppState`

**Files:**
- Modify: `Glyphoid/AppState.swift`

This task replaces the entire favorites subsystem in AppState. The changes are:

| Remove | Add / Change |
|--------|-------------|
| `favoritesStore: FavoritesStore` | `recentlyUsedStore: RecentlyUsedStore` |
| `@Published filteredFavorites` | `@Published private(set) var recentGlyphs: [GlyphEntry] = []` |
| `@Published unavailableFavoriteCPs` | *(removed, no stub concept)* |
| `toggleFavorite(_:)` | `clearRecents()` |
| `clearFavorites()` | *(absorbed into clearRecents)* |
| favorites Combine pipeline | recents Combine sink |
| immediate-clear Merge publisher | *(removed, no longer needed)* |
| favorites logic in `applyFilters()` | simplified: just `filteredGlyphs = filtered` |
| `filteredFavorites + filteredGlyphs` in `navigateGrid` | `recentGlyphs + filteredGlyphs` |

- [ ] **Step 1: Replace the full `AppState.swift` with the refactored version**

```swift
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
    let recentlyUsedStore: RecentlyUsedStore
    let windowStateStore: WindowStateStore
    let focusTracker: AppFocusTracker
    let windowManager: WindowManager

    // MARK: - Published state

    /// All glyphs for the current font, unfiltered
    @Published private(set) var allGlyphs: [GlyphEntry] = []

    /// Glyphs shown in the grid (filtered by search + category)
    @Published private(set) var filteredGlyphs: [GlyphEntry] = []

    /// The 20 most-recently used glyphs (shown at top, always visible).
    @Published private(set) var recentGlyphs: [GlyphEntry] = []

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
        self.recentlyUsedStore = RecentlyUsedStore()
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

        // Wire recents changes → update recentGlyphs (convert RecentGlyph → GlyphEntry)
        recentlyUsedStore.$recents
            .sink { [weak self] recents in
                self?.recentGlyphs = recents.map {
                    GlyphEntry(codepoint: $0.codepoint,
                               character: $0.character,
                               germanName: $0.germanName,
                               category: $0.category)
                }
            }
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
        // Record before anything else — both the insert and clipboard-fallback paths
        // deliver the character to the user, so recording is unconditional.
        recentlyUsedStore.record(glyph)

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
        recentlyUsedStore.record(glyph)
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
        recentlyUsedStore.record(glyph)
        let family = windowStateStore.selectedFontFamily
        let style  = windowStateStore.selectedStyle
        let svg = svgExporter.textSVG(character: glyph.character,
                                       fontFamily: family, style: style)
        clipboardService.copySVGText(svg)
        showToast("Text-SVG kopiert")
    }

    func clearRecents() {
        recentlyUsedStore.clearAll()
    }

    func navigateGrid(direction: NavigationDirection) {
        let allVisible = recentGlyphs + filteredGlyphs
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
        filteredGlyphs = allGlyphs.filter { matches(glyph: $0, query: query, category: category) }
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
```

- [ ] **Step 2: Build (⌘B) — expect errors in `GlyphCellView` and `GlyphGridView` referencing removed properties. Do not fix them yet; proceed to the next task.**

- [ ] **Step 3: Commit the AppState changes (build errors are expected at this point)**

```bash
git add Glyphoid/AppState.swift
git commit -m "feat: wire RecentlyUsedStore into AppState, remove favorites subsystem"
```

---

## Chunk 3: View layer and cleanup

### Task 4: Simplify `GlyphCellView`

**Files:**
- Modify: `Glyphoid/Views/Grid/GlyphCellView.swift`

Remove `isFavorite`, `isUnavailable`, `onFavoriteToggle`. No stub rendering, no star button.

- [ ] **Step 1: Replace `Glyphoid/Views/Grid/GlyphCellView.swift` with the simplified version**

```swift
import SwiftUI

struct GlyphCellView: View {
    let glyph: GlyphEntry
    let fontFamily: String
    let cellSize: Double
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void

    @State private var isHovered = false
    @State private var lastTapDate: Date = .distantPast

    var body: some View {
        Text(glyph.character)
            .font(.custom(fontFamily, size: cellSize * 0.6))
            .foregroundColor(.primary)
            .frame(width: cellSize, height: cellSize)
            .background(cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .onHover { isHovered = $0 }
            .onTapGesture {
                let now = Date()
                if now.timeIntervalSince(lastTapDate) < 0.35 {
                    onDoubleTap()
                } else {
                    onTap()
                }
                lastTapDate = now
            }
            .help("\(glyph.germanName) · \(glyph.unicodeLabel)")
    }

    private var cellBackground: Color {
        if isSelected { return Color.accentColor.opacity(0.2) }
        if isHovered  { return Color(.selectedContentBackgroundColor).opacity(0.4) }
        return Color(.controlBackgroundColor)
    }
}
```

---

### Task 5: Update `GlyphGridView` — recents section

**Files:**
- Modify: `Glyphoid/Views/Grid/GlyphGridView.swift`

- [ ] **Step 1: Replace `Glyphoid/Views/Grid/GlyphGridView.swift`**

```swift
import SwiftUI

struct GlyphGridView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        let cellSize   = state.windowStateStore.cellSize
        let fontFamily = state.windowStateStore.selectedFontFamily
        let columns    = [GridItem(.adaptive(minimum: cellSize, maximum: cellSize), spacing: 4)]

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    Color.clear.frame(height: 0).id("glyphScrollTop")

                    if !state.recentGlyphs.isEmpty {
                        recentsSectionHeader

                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(state.recentGlyphs) { glyph in
                                GlyphCellView(
                                    glyph: glyph,
                                    fontFamily: fontFamily,
                                    cellSize: cellSize,
                                    isSelected: state.selectedGlyph?.id == glyph.id,
                                    onTap: { state.selectGlyph(glyph) },
                                    onDoubleTap: { Task { await state.insertGlyphAsync(glyph) } }
                                )
                            }
                        }
                        .padding(.horizontal, 8)

                        Divider()
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                    }

                    if state.filteredGlyphs.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(state.filteredGlyphs) { glyph in
                                GlyphCellView(
                                    glyph: glyph,
                                    fontFamily: fontFamily,
                                    cellSize: cellSize,
                                    isSelected: state.selectedGlyph?.id == glyph.id,
                                    onTap: { state.selectGlyph(glyph) },
                                    onDoubleTap: { state.insertGlyph(glyph) }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .id("topAnchor")
                    }

                    Spacer(minLength: 16)
                }
                .padding(.top, 8)
            }
            .onChange(of: state.windowStateStore.selectedFontFamily) { _ in resetScroll(proxy: proxy) }
            .onChange(of: state.windowStateStore.selectedCategory)   { _ in resetScroll(proxy: proxy) }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { state.gridWidth = geo.size.width }
                    .onChange(of: geo.size.width) { state.gridWidth = $0 }
            }
        )
    }

    private var recentsSectionHeader: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text("Zuletzt verwendet")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { state.clearRecents() }) {
                Text("Alle entfernen")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 60)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Keine Glyphen gefunden")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
    }

    private func resetScroll(proxy: ScrollViewProxy) {
        proxy.scrollTo("glyphScrollTop", anchor: .top)
    }
}
```

- [ ] **Step 2: Build (⌘B) — must succeed with zero errors**

- [ ] **Step 3: Run all tests (⌘U) — all tests must pass**

- [ ] **Step 4: Commit**

```bash
git add Glyphoid/Views/Grid/GlyphCellView.swift \
        Glyphoid/Views/Grid/GlyphGridView.swift
git commit -m "feat: replace favorites section with recents section, simplify GlyphCellView"
```

---

### Task 6: Delete `FavoritesStore` and its tests

**Files:**
- Delete: `Glyphoid/Services/FavoritesStore.swift`
- Delete: `GlyphoidTests/FavoritesStoreTests.swift`

- [ ] **Step 1: Delete `FavoritesStore.swift`**

In Xcode: right-click `FavoritesStore.swift` in the Project Navigator → Delete → Move to Trash.

Or from the shell (must also remove from the Xcode project file):
```bash
rm Glyphoid/Services/FavoritesStore.swift
rm GlyphoidTests/FavoritesStoreTests.swift
```

Then open `Glyphoid.xcodeproj` and remove the file references from the project navigator (Xcode will show them in red — delete them).

- [ ] **Step 2: Build (⌘B) — must succeed. If any "file not found" linker errors appear, confirm the project file references were removed.**

- [ ] **Step 3: Run all tests (⌘U) — all tests must pass**

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: remove FavoritesStore and replace favorites with recently-used glyphs"
```

---

## Summary of all files changed

| Action | Path |
|--------|------|
| Create | `Glyphoid/Models/RecentGlyph.swift` |
| Create | `Glyphoid/Services/RecentlyUsedStore.swift` |
| Delete | `Glyphoid/Services/FavoritesStore.swift` |
| Replace | `Glyphoid/AppState.swift` |
| Replace | `Glyphoid/Views/Grid/GlyphCellView.swift` |
| Replace | `Glyphoid/Views/Grid/GlyphGridView.swift` |
| Create | `GlyphoidTests/RecentlyUsedStoreTests.swift` |
| Delete | `GlyphoidTests/FavoritesStoreTests.swift` |
