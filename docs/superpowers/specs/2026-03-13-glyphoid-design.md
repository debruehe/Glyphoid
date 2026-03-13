# Glyphoid – Design Spec
**Datum:** 2026-03-13
**Status:** Approved

---

## Überblick

Glyphoid ist eine native macOS-Companion-App als Glyphen-Picker für professionelle Grafiksoftware (InDesign, Illustrator, After Effects, Figma). Sie zeigt alle Glyphen einer installierten Schrift in einem übersichtlichen Raster, erlaubt Suche, Favoriten, direktes Einfügen und SVG-Export.

---

## Technologie

- **Plattform:** macOS, nativ — Mindestanforderung: macOS 14 (Sonoma)
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
1. Schriftfamilien-Auswahl (durchsuchbares Dropdown — listet alle installierten Schriften alphabetisch)
2. Schriftgewicht/Style (Dropdown — zeigt nur die in der gewählten Familie tatsächlich vorhandenen Styles)
3. Größenregler (Slider — steuert Zellgröße im Raster; Min: 24pt, Standard: 48pt, Max: 96pt)
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

### Auswahl-Zustand
- Eine Zelle gilt als ausgewählt nach einfachem oder doppeltem Klick
- Doppelklick wählt die Zelle aus (wie einfacher Klick) und fügt zusätzlich ein
- Die Zelle bleibt nach Doppelklick ausgewählt; `Cmd+C` / `Cmd+Shift+C` bleiben aktiv
- `Cmd+C` und `Cmd+Shift+C` sind **nur aktiv wenn eine Zelle ausgewählt ist**
- Pfeiltasten navigieren zwischen Zellen; Enter/Space wählen die fokussierte Zelle aus

### Einfacher Klick
- Zelle wird blau hervorgehoben (Slate-Akzentfarbe)
- Footer / Statusbereich zeigt: deutscher Name, Unicode-Codepunkt (z.B. U+2192)
- Verfügbare Tastaturkürzel werden im Footer angezeigt:
  - `Cmd+C` → SVG mit echten Vektorpfaden in Zwischenablage — überschreibt vorherigen Clipboard-Inhalt
  - `Cmd+Shift+C` → SVG mit Text-Element in Zwischenablage — überschreibt vorherigen Clipboard-Inhalt
- Falls Vektorexport für eine Glyphe nicht möglich (sehr selten): kurze Hinweismeldung, Fallback auf Text-SVG

### Doppelklick
- Zelle wird ausgewählt (wie einfacher Klick), dann wird das Zeichen in die zuletzt aktive App eingefügt
- Mechanismus: Zeichen (als Klartext) in Zwischenablage → `Cmd+V` in Ziel-App simulieren (via Accessibility API)
- Getestet mit: InDesign, Illustrator, After Effects, Figma (Desktop)
- **"Zuletzt aktive App" Tracking:** Glyphoid beobachtet via `NSWorkspace` welche App zuletzt im Vordergrund war, bevor Glyphoid den Fokus erhielt. Im Floating-Panel-Modus (immer im Vordergrund) nimmt Glyphoid den Fokus nicht weg — die Ziel-App bleibt aktiv, `Cmd+V` wird direkt dort ausgeführt. Im normalen Fenstermodus wird die zuvor frontmost App gespeichert und als Ziel verwendet.
- **Zwischenablage nach Doppelklick:** Das Zeichen (Klartext) verbleibt in der Zwischenablage nach dem Einfügen. Ein nachfolgendes `Cmd+C` ersetzt es mit dem SVG — das ist das erwartete Verhalten.
- **Fallback (kein aktives Textfeld / Ziel-App unterstützt kein Einfügen):** Das Zeichen wird trotzdem in die Zwischenablage kopiert, kurze Hinweismeldung in Glyphoid
- **Accessibility-Berechtigung:** Beim ersten Doppelklick pro App-Start prüft die App ob die Berechtigung erteilt ist. Falls nicht, erscheint einmalig ein Dialog mit Erklärung und direktem Link zu Systemeinstellungen. Ohne Berechtigung ist nur der Fallback verfügbar.
- **Berechtigung nachträglich widerrufen:** Fallback (Zwischenablage + Hinweis) ohne erneuten Dialog

### Suche
Filtert das Raster in Echtzeit nach:
- Deutschem Glyphennamen (z.B. "Pfeil")
- Der Glyphe selbst (direktes Eintippen des Zeichens)
- Unicode-Codepunkt (z.B. "2192")
- Kategorie (z.B. "Währung")

Wenn gleichzeitig ein Kategoriefilter in der Sidebar aktiv ist, gelten beide Filter zusammen (AND-Logik): Es werden nur Glyphen angezeigt, die sowohl zur Kategorie als auch zum Suchbegriff passen.

**Favoriten im gefilterten Zustand:** Favoriten folgen denselben Filter-Regeln wie normale Glyphen — sie verschwinden aus dem Favoriten-Bereich wenn sie nicht zum aktiven Suchbegriff oder Kategoriefilter passen.

**Leere Suchergebnisse:** Das Raster zeigt eine zentrierte Meldung "Keine Glyphen gefunden" ohne Zellen.

---

## Favoriten

- Schriftunabhängig gespeichert als Unicode-Codepunkt (U+XXXX) — nicht als Name; dadurch bleiben Favoriten bei CLDR-Updates stabil
- Erscheinen immer in den ersten Reihen des Rasters, visuell abgesetzt
- So sieht man sofort wie Lieblingsglyphen in verschiedenen Schriften aussehen
- Persistent gespeichert (UserDefaults)
- **Wenn eine Favoriten-Glyphe in der aktuell gewählten Schrift nicht vorhanden ist:** Sie wird ausgegraut im Favoriten-Bereich angezeigt mit einem Hinweis-Icon. Sie ist **nicht interaktiv** — kein Hover, keine Auswahl, kein Kopieren möglich.

---

## Deutsche Glyphennamen & Kategorien

**Glyphennamen:** Unicode CLDR Datenbank (deutsche Locale), mit der App gebündelt; Version im "Über Glyphoid"-Dialog angezeigt. Bei App-Updates wird die gebündelte Version ersetzt; Favoriten (als Codepunkte gespeichert) bleiben gültig. Fallback auf englischen Unicode-Namen wenn keine deutsche Übersetzung vorhanden.

**Kategorien:** Aus der Unicode Character Database (UCD) — `Blocks.txt` und `UnicodeData.txt`. Die UCD-Blöcke werden auf Glyphoid-Kategorien gemappt:
- Pfeile → Unicode Blocks: Arrows, Supplemental Arrows A/B/C, Miscellaneous Symbols and Arrows
- Währung → Currency Symbols, ergänzt durch einzelne Währungszeichen aus Latin-1
- Mathematik → Mathematical Operators, Supplemental Mathematical Operators, Mathematical Alphanumeric Symbols
- Buchstaben → Basic Latin, Latin-1 Supplement, Latin Extended A/B, und weitere Buchstabenblöcke
- Satzzeichen → General Punctuation, Supplemental Punctuation, CJK Symbols and Punctuation (soweit relevant)
- Sonstiges → alles was keiner der obigen Kategorien zugeordnet ist

---

## Visuelles Design

- **Stil:** Slate / macOS-nah (kühle Grautöne, blauer Akzent)
- **Dark Mode:** Hintergründe #171b22 / #1f2530, Text #dde1e7, Akzent #4a9eff, Zelle hover #283040
- **Light Mode:** Hintergrund #f0f2f5 / #ffffff, Text #1a1d23, Akzent #0066cc, Zelle hover #e0e8f5
- **Mindestfenstergröße:** 480pt × 480pt; Sidebar feste Breite 140pt
- Beim Wechsel von Schrift oder Kategoriefilter: Raster scrollt zurück zum Anfang
- **Typografie:** SF Pro (System-Schrift), Glyphen werden in der jeweils gewählten Schrift gerendert
- Klar, professionell, werkzeugartig — keine übertriebenen Animationen

---

## SVG-Ausgabeformat

- **Vektorpfad (Cmd+C):** `viewBox="0 0 1000 1000"`, schwarze Füllung (`fill="#000000"`), kein Stroke; Koordinaten aus dem Font-Koordinatensystem (CoreGraphics CGPath), skaliert auf 1000 UPM
- **Text-SVG (Cmd+Shift+C):** `viewBox="0 0 1000 1000"`, `<text x="500" y="500" text-anchor="middle" dominant-baseline="central" font-family="[Schriftname]" font-weight="[Gewicht]" font-style="[Style]" font-size="800" fill="#000000">[Zeichen]</text>`

## Fenster-Zustand (Persistenz)

Folgende Zustände werden zwischen App-Starts gespeichert und wiederhergestellt:
- Fenstergröße und -position
- Pin-Zustand (schwebend / normal)
- Zuletzt gewählte Schriftfamilie und Style
- Slider-Position (Zellgröße)
- Aktiver Kategoriefilter

## "Über Glyphoid"-Dialog

Enthält: App-Version, Copyright, verwendete CLDR-Version, Link zur Projektseite (sofern vorhanden).

## Nicht im Scope

- Windows / Linux Support
- iCloud-Sync
- App Store Distribution
- Eigene Schriften importieren (nur installierte Systemfonts)
- Schriftvorschau-Text (Pangram etc.) — nur Glyphen-Raster
