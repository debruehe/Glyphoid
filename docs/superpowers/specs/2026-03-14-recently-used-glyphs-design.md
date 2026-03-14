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
    let category: GlyphCategory   // already Codable
}
```

Snapshot captured at time of use. No runtime lookup needed. `id` is `codepoint`.

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
- Call `recentlyUsedStore.record(glyph)` at the start of `insertGlyph(_:)`, `copyVectorSVG(for:)`, `copyTextSVG(for:)`
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

## Persistence Format

```json
[
  { "codepoint": 8594, "character": "→", "germanName": "nach rechts weisender Pfeil", "category": "arrows" },
  ...
]
```

Stored under `UserDefaults` key `"glyphoid.recentlyUsed"`.

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
