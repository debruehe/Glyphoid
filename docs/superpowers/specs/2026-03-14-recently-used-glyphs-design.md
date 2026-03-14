# Recently Used Glyphs — Design Spec
Date: 2026-03-14

## Overview

Remove the broken favorites feature entirely. Replace it with a "recently used" section that automatically tracks the last 20 glyphs the user inserted or copied. Recents persist across app restarts and are stored as full snapshots so no font lookup is required at render time.

## Trigger Events

A glyph is recorded as recently used when:
- The user double-clicks it (insert via `insertGlyph()`)
- The user copies it as vector SVG (`copyVectorSVG()`)
- The user copies it as text SVG (`copyTextSVG()`)

## Data Model

### `RecentGlyph` (new, `Models/RecentGlyph.swift`)

```swift
struct RecentGlyph: Codable, Identifiable, Hashable {
    let codepoint: UInt32
    let character: String
    let germanName: String
    let category: GlyphCategory
}
```

Snapshot captured at time of use. No runtime lookup needed. `var id: UInt32 { codepoint }`.

`GlyphCategory` is `RawRepresentable` with German display strings as raw values (`"Pfeile"` etc.), so synthesised `Codable` would encode the wrong value. `RecentGlyph` must provide a **custom `Codable` implementation** that encodes/decodes `category` via `jsonKey` (the English key already used in `glyph-categories.json`, e.g. `"arrows"`). The stored JSON format is:

```json
[
  { "codepoint": 8594, "character": "→", "germanName": "nach rechts weisender Pfeil", "category": "arrows" }
]
```

`ForEach` in the recents grid uses `\.id` via `Identifiable` (not an explicit `id:` keypath).

## Service Layer

### `RecentlyUsedStore` (new, `Services/RecentlyUsedStore.swift`)

- `@Published private(set) var recents: [RecentGlyph]` — ordered most-recent-first, max 20 entries
- `record(_ glyph: GlyphEntry)` — inserts a snapshot at index 0, removes any existing entry for the same codepoint, then trims to 20
- `clearAll()` — empties the list
- Persists as JSON (`[RecentGlyph]`) in `UserDefaults` under key `"glyphoid.recentlyUsed"`
- `load()` called in `init()`; `save()` called after every mutation

### `FavoritesStore` (deleted)

`FavoritesStore.swift` is removed entirely.

## AppState Changes

- Replace `favoritesStore: FavoritesStore` with `recentlyUsedStore: RecentlyUsedStore`
- Add `@Published private(set) var recentGlyphs: [GlyphEntry] = []`
  - Kept in sync via `recentlyUsedStore.$recents.sink` which converts `[RecentGlyph] → [GlyphEntry]`
- Remove `filteredFavorites`, `unavailableFavoriteCPs`, `toggleFavorite(_:)`, `clearFavorites()`
- Add `clearRecents()` delegating to `recentlyUsedStore.clearAll()`
- Call `recentlyUsedStore.record(glyph)` **before** the accessibility-permission early-return in `insertGlyph(_:)` — the character is delivered to the user on both the insert and the clipboard-fallback paths, so recording happens unconditionally at the top of the method
- Call `recentlyUsedStore.record(glyph)` at the start of `copyVectorSVG(for:)` — fires once regardless of whether the vector or text-SVG fallback branch executes
- Call `recentlyUsedStore.record(glyph)` at the start of `copyTextSVG(for:)`
- In `navigateGrid`, replace `filteredFavorites` with `recentGlyphs` in the `allVisible` pool: `let allVisible = recentGlyphs + filteredGlyphs`
- Remove all favorites-related Combine subscriptions (including the immediate-clear subscription added in the previous fix attempt)
- `applyFilters()` and `reloadGlyphs()` are unchanged — recents are independent of font/search/category filters

## View Layer

### `GlyphCellView` — simplified

Remove parameters: `isFavorite`, `isUnavailable`, `onFavoriteToggle`.
Remove: star button overlay, stub rendering, unavailable background colour.
Keep: hover, selection highlight, tap, double-tap.

### `GlyphGridView` — recents section replaces favorites section

```
if !state.recentGlyphs.isEmpty {
    // Header: star.clock icon + "Zuletzt verwendet" label + "Alle entfernen" button
    LazyVGrid of state.recentGlyphs using simplified GlyphCellView
    Divider
}
```

Recents are **not** filtered by search query or category — they are a persistent usage history shown above the filtered grid at all times.

Recents cells render `glyph.character` with the currently selected font. If the font does not support the character, SwiftUI falls back to the system font automatically — no stub logic needed.

The empty-state condition changes from `filteredGlyphs.isEmpty && filteredFavorites.isEmpty` to simply `filteredGlyphs.isEmpty` — recents are shown in their own section above and do not affect the empty state of the main grid.

## Persistence Format

Stored under `UserDefaults` key `"glyphoid.recentlyUsed"` as JSON-encoded `[RecentGlyph]`. The `category` field uses `jsonKey` values (`"arrows"`, `"letters"`, etc.), not the German display strings.

## Files Changed

| Action | File |
|--------|------|
| Add | `Glyphoid/Models/RecentGlyph.swift` |
| Add | `Glyphoid/Services/RecentlyUsedStore.swift` |
| Delete | `Glyphoid/Services/FavoritesStore.swift` |
| Modify | `Glyphoid/AppState.swift` |
| Modify | `Glyphoid/Views/Grid/GlyphCellView.swift` |
| Modify | `Glyphoid/Views/Grid/GlyphGridView.swift` |
| Delete | `GlyphoidTests/FavoritesStoreTests.swift` |
| Add | `GlyphoidTests/RecentlyUsedStoreTests.swift` |

## Out of Scope

- Filtering recents by font, search, or category
- Showing recents as "unavailable" stubs
- Per-font recents history
- Undo/redo for clears
