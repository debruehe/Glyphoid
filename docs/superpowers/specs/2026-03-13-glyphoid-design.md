# Glyphoid – Design Spec
**Datum:** 2026-03-13
**Status:** Approved

---

## Überblick

Glyphoid ist eine native macOS-Companion-App als Glyphen-Picker für professionelle Grafiksoftware (InDesign, Illustrator, After Effects, Figma). Sie zeigt alle Glyphen einer installierten Schrift in einem übersichtlichen Raster, erlaubt Suche, Favoriten, direktes Einfügen und SVG-Export.

---

## Technologie

- **Plattform:** macOS, nativ
- **Framework:** SwiftUI
- **Schriftzugriff:** CoreText + NSFontManager (Systemfonts)
- **SVG-Vektorexport:** CoreGraphics (CGPath aus Glyphen-Umrissen) — keine externe Bibliothek
- **Datenspeicherung:** Lokal (UserDefaults / App-eigene Datenbank)
- **Lokalisierung:** Deutsch (UI + Glyphennamen via Unicode CLDR)
- **Keine Internetverbindung, kein Account, kein App Store erforderlich**

---

## Fenster & Verhalten

- Startet als normales, frei verschiebbares und größenveränderbares Fenster
- Pin-Symbol in der Titelleiste schaltet zwischen normalem Fenster und "immer im Vordergrund" (Floating Panel) um
- Pin-Zustand wird gespeichert und beim nächsten Start wiederhergestellt
- Folgt automatisch dem macOS Dark/Light Mode — kein manueller Schalter

---

## Layout

Sidebar-links-Layout:

```
┌─────────────────────────────────────────────┐
│ ● ● ●   Glyphoid                     📌     │
├──────────┬──────────────────────────────────┤
│ SCHRIFT  │  ⌕ Suchen...                     │
│ Helvet.  │                                  │
│ Regular  │  ★ Favoriten (erste Reihen)       │
│          │  ─────────────────────────────   │
│ GRÖẞE   │  A  B  →  ©  ♥  €  æ  ß  ∑  π   │
│ ──●────  │  …  «  »  ™  ®  °  ±  ×  ÷  ≠   │
│          │  (alle Glyphen der Schrift)       │
│ FILTER   │                                  │
│ Alle     │                                  │
│ Pfeile   │                                  │
│ Währung  │                                  │
│ Buchst.  │                                  │
└──────────┴──────────────────────────────────┘
```

### Sidebar (von oben nach unten)
1. Schriftfamilien-Auswahl (Dropdown oder scrollbare Liste)
2. Schriftgewicht/Style (Regular, Bold, Italic, …)
3. Größenregler (Slider — steuert Zellgröße im Raster)
4. Kategoriefilter: Alle / Pfeile / Buchstaben / Währung / Mathematik / Satzzeichen / Sonstiges

---

## Glyphen-Raster

- Zeigt alle Glyphen der gewählten Schrift
- Zellgröße wird durch Größenregler gesteuert (klein = mehr Glyphen sichtbar, groß = besser lesbar)
- Hover: Tooltip mit deutschem Glyphennamen (z.B. "Rechtspfeil"), Unicode-Codepunkt
- Favoriten erscheinen in einem abgesetzten Bereich ganz oben im Raster (vor allen anderen Glyphen), getrennt durch eine feine Linie
- Stern-Icon erscheint beim Hovern auf jeder Zelle → Klick togglet Favorit

---

## Interaktionen

### Einfacher Klick
- Zelle wird blau hervorgehoben (Slate-Akzentfarbe)
- Footer / Statusbereich zeigt: deutscher Name, Unicode-Codepunkt (z.B. U+2192)
- Verfügbare Tastaturkürzel werden angezeigt:
  - `Cmd+C` → SVG mit echten Vektorpfaden (CGPath aus Schriftdatei) in Zwischenablage
  - `Cmd+Shift+C` → SVG mit Text-Element in Zwischenablage
- Falls Vektorexport für eine Glyphe nicht möglich (sehr selten): kurze Hinweismeldung, Fallback auf Text-SVG

### Doppelklick
- Zeichen wird in die zuletzt aktive App eingefügt (sofern dort ein Textfeld aktiv war)
- Mechanismus: Zeichen in Zwischenablage → `Cmd+V` in Ziel-App simulieren (via Accessibility API)
- Getestet mit: InDesign, Illustrator, After Effects, Figma (Desktop)

### Suche
Filtert das Raster in Echtzeit nach:
- Deutschem Glyphennamen (z.B. "Pfeil")
- Der Glyphe selbst (direktes Eintippen des Zeichens)
- Unicode-Codepunkt (z.B. "2192")
- Kategorie (z.B. "Währung")

---

## Favoriten

- Schriftunabhängig gespeichert (z.B. "Rechtspfeil" ist Favorit in allen Schriften)
- Erscheinen immer in den ersten Reihen des Rasters, visuell abgesetzt
- So sieht man sofort wie Lieblingsglyphen in verschiedenen Schriften aussehen
- Persistent gespeichert (UserDefaults)

---

## Deutsche Glyphennamen

- Basis: Unicode CLDR Datenbank (offizieller internationaler Standard)
- Fallback: englischer Unicode-Name wenn keine deutsche Übersetzung vorhanden
- Kategorien ebenfalls aus CLDR

---

## Visuelles Design

- **Stil:** Slate / macOS-nah (kühle Grautöne, blauer Akzent)
- **Dark Mode:** Hintergründe #171b22 / #1f2530, Text #dde1e7, Akzent #4a9eff
- **Light Mode:** Helle Äquivalente, folgt macOS-Systemfarben
- **Typografie:** SF Pro (System-Schrift), Glyphen werden in der jeweils gewählten Schrift gerendert
- Keine Abgerundeten Ecken-Übertreibung — klar, professionell, werkzeugartig

---

## Nicht im Scope

- Windows / Linux Support
- iCloud-Sync
- App Store Distribution
- Eigene Schriften importieren (nur installierte Systemfonts)
- Schriftvorschau-Text (Pangram etc.) — nur Glyphen-Raster
