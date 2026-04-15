# Glyphoid

A native macOS glyph browser and picker. Browse, search, and insert Unicode characters directly into any app.

## Features

- **Browse by category** — arrows, letters, currency, math, punctuation, and more
- **Search by name** — powered by CLDR German Unicode names
- **Insert anywhere** — pastes the character directly into the frontmost app via Accessibility
- **Copy as SVG** — export a glyph as a vector path SVG or text-element SVG
- **Recently used** — quick access to your last-used glyphs
- **Pin window** — keep Glyphoid floating above other windows (`⌘⇧P`)
- **Keyboard navigation** — arrow keys to navigate the grid, Return or Space to insert

## Requirements

- macOS 14 Sonoma or later
- Xcode 15+

## Build

```sh
# Generate Xcode project from project.yml (requires xcodegen)
xcodegen generate

# Then open and build in Xcode
open Glyphoid.xcodeproj
```

## Project Structure

```
Glyphoid/
├── Models/        # GlyphEntry, GlyphCategory, FontFamily, RecentGlyph
├── Views/         # SwiftUI views — grid, sidebar, status bar, sheets
├── Services/      # Font loading, clipboard, SVG export, window state, recents
├── Resources/     # Bundled CLDR glyph-name JSON, glyph-categories JSON
GlyphoidTests/     # Unit tests
docs/              # Design specs and planning docs
project.yml        # XcodeGen project definition
```

## License

MIT
