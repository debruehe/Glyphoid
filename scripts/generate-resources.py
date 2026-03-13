#!/usr/bin/env python3
"""
Generates Glyphoid's bundled resource files:
  - Glyphoid/Resources/cldr-de-names.json   { "2192": "Rechtspfeil", ... }
  - Glyphoid/Resources/glyph-categories.json { "2192": "arrows", ... }

Run once to (re-)generate. Requires: requests, lxml
  pip3 install requests lxml
"""
import json, re, sys
from pathlib import Path
import requests
from lxml import etree

OUT_DIR = Path(__file__).parent.parent / "Glyphoid" / "Resources"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ── 1. German CLDR annotation names ──────────────────────────────────────────
CLDR_URL = (
    "https://raw.githubusercontent.com/unicode-org/cldr/main"
    "/common/annotations/de.xml"
)
print("Downloading CLDR German annotations…")
xml_bytes = requests.get(CLDR_URL, timeout=30).content
root = etree.fromstring(xml_bytes)

names: dict[str, str] = {}
for ann in root.findall(".//annotation"):
    cp_str = ann.get("cp", "")
    type_attr = ann.get("type", "")
    if not cp_str or type_attr == "tts":
        # tts = text-to-speech (the short name we want is the OTHER one)
        pass
    if type_attr == "tts":
        # This IS the short human-readable name — use it
        cp_str = cp_str.strip()
        # cp can be a single char or a sequence; skip multi-codepoint sequences
        cps = [ord(c) for c in cp_str]
        if len(cps) == 1:
            hex_key = format(cps[0], "X")
            names[hex_key] = ann.text.strip() if ann.text else ""

print(f"  Loaded {len(names)} German names from CLDR")

# ── 2. Unicode block → Glyphoid category mapping ─────────────────────────────
BLOCKS_URL = "https://unicode.org/Public/UCD/latest/ucd/Blocks.txt"
print("Downloading Unicode Blocks.txt…")
blocks_text = requests.get(BLOCKS_URL, timeout=30).text

# Map block name substrings → Glyphoid category key
BLOCK_CATEGORY: list[tuple[str, str]] = [
    # Arrows
    ("Arrows",                  "arrows"),
    ("Supplemental Arrows",     "arrows"),
    ("Miscellaneous Symbols and Arrows", "arrows"),
    ("Dingbats",                "arrows"),
    # Currency
    ("Currency Symbols",        "currency"),
    # Math
    ("Mathematical Operators",  "math"),
    ("Supplemental Mathematical Operators", "math"),
    ("Mathematical Alphanumeric Symbols",   "math"),
    ("Letterlike Symbols",      "math"),
    ("Number Forms",            "math"),
    # Punctuation / General
    ("General Punctuation",     "punctuation"),
    ("Supplemental Punctuation","punctuation"),
    ("CJK Symbols and Punctuation", "punctuation"),
    ("Small Form Variants",     "punctuation"),
    ("Halfwidth and Fullwidth Forms", "punctuation"),
    # Letters (Latin + common scripts)
    ("Basic Latin",             "letters"),
    ("Latin-1 Supplement",      "letters"),
    ("Latin Extended",          "letters"),
    ("IPA Extensions",          "letters"),
    ("Spacing Modifier Letters","letters"),
    ("Combining Diacritical",   "letters"),
    ("Greek",                   "letters"),
    ("Cyrillic",                "letters"),
    ("Hebrew",                  "letters"),
    ("Arabic",                  "letters"),
    ("Phonetic Extensions",     "letters"),
]

# Parse blocks into list of (start, end, category)
block_ranges: list[tuple[int, int, str]] = []
for line in blocks_text.splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    m = re.match(r"([0-9A-F]+)\.\.([0-9A-F]+)\s*;\s*(.+)", line)
    if not m:
        continue
    start, end, block_name = int(m.group(1), 16), int(m.group(2), 16), m.group(3).strip()
    cat = "other"
    for substr, mapped in BLOCK_CATEGORY:
        if substr.lower() in block_name.lower():
            cat = mapped
            break
    block_ranges.append((start, end, cat))

def category_for(cp: int) -> str:
    for start, end, cat in block_ranges:
        if start <= cp <= end:
            return cat
    return "other"

all_cps: set[int] = set()
for start, end, _ in block_ranges:
    if end <= 0x1FFFF:
        all_cps.update(range(start, min(end + 1, 0x20000)))

categories: dict[str, str] = {}
for cp in sorted(all_cps):
    if 0xD800 <= cp <= 0xDFFF:
        continue
    cat = category_for(cp)
    categories[format(cp, "X")] = cat

print(f"  Built category map for {len(categories)} codepoints")

# ── 4. Write output ───────────────────────────────────────────────────────────
names_path = OUT_DIR / "cldr-de-names.json"
cats_path  = OUT_DIR / "glyph-categories.json"

with open(names_path, "w", encoding="utf-8") as f:
    json.dump(names, f, ensure_ascii=False, indent=None, separators=(",", ":"))
print(f"  Wrote {names_path} ({names_path.stat().st_size // 1024} KB)")

with open(cats_path, "w", encoding="utf-8") as f:
    json.dump(categories, f, ensure_ascii=False, indent=None, separators=(",", ":"))
print(f"  Wrote {cats_path} ({cats_path.stat().st_size // 1024} KB)")

print("Done.")
