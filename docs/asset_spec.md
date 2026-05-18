# Divinus — Tile Asset Generation Specification

## Canvas & Grid Format

| Property | Value |
|----------|-------|
| Sheet dimensions | **1024 × 1280 pixels** |
| Grid | 2 columns × 5 rows |
| Tile size | **512 × 256 px** per tile (2:1 isometric ratio) |
| Tile (0,0) origin | Pixel (0, 0) — zero padding/margin |
| Format | PNG, RGBA 32-bit |
| Transparency | Outside the isometric diamond = fully transparent (alpha = 0) |

> Godot reads tile (col,row) at pixel offset (col×512, row×256).
> Zero padding means tile content must start exactly at those offsets — no empty margin inside cells.

### Sheet Tile Layout

```
Column →    0              1
         +----------+----------+   <- each column = 512 px
Row 0    |   (0,0)  |   (1,0)  |
         +----------+----------+
Row 1    |   (0,1)  |   (1,1)  |
         +----------+----------+
Row 2    |   (0,2)  |   (1,2)  |
         +----------+----------+
Row 3    |   (0,3)  |   (1,3)  |
         +----------+----------+
Row 4    |   (0,4)  |   (1,4)  |
         +----------+----------+
              ^ each row = 256 px => total 1280 px tall
```

## Isometric Diamond Shape (per tile)

Every tile is a diamond (rhombus) within its 512×256 cell:

- Top vertex:    (256,   0) — center of top edge
- Right vertex:  (511, 127) — rightmost pixel
- Bottom vertex: (256, 255) — center of bottom edge
- Left vertex:   (  0, 127) — leftmost pixel

Pixels outside this diamond = fully transparent.

## Style Requirements (ALL tiles)

| Property | Value |
|----------|-------|
| Art style | Painted 2D — NOT pixel art, NOT 3D render |
| Perspective | True isometric, parallel projection, ~30 degree elevation |
| Light source | Top-left (northwest) |
| Shadow direction | Subtle darkening on south/east face |
| Seamless | No visible border between adjacent tiles when laid in grid |
| No UI | No icons, text, numbers, or UI chrome |
| No internal grid lines | No separator lines between tiles within the sheet |

## Color Distinctiveness Rule

Each biome sheet must be visually unmistakable without engine tinting.
A player must identify the biome from tile color alone at a glance.

---

## Biome Sheets — 5 Files

### File 1: `tiles_water.png` — Water / Ocean

**Palette:**

| Swatch | Hex | Role |
|--------|-----|------|
| Deep ocean | `#1a4f7a` | Base dark water |
| Mid water | `#2575b8` | Main fill |
| Shallow | `#5aacd4` | Edges, highlights |
| Foam/surf | `#c3e8f5` | Accent |
| Bright highlight | `#dff4ff` | Specular |

**10 Variants (row by row):**

| Row | Col 0 | Col 1 |
|-----|-------|-------|
| 0 | Deep ocean, calm | Deep ocean, slight shimmer |
| 1 | Mid-depth ripple | Mid-depth crosshatch ripple |
| 2 | Shallow clear water | Shallow with sandy tint |
| 3 | Seafoam at edge | Foam with bubble hints |
| 4 | Small wave pattern | Active stirred water |

**AI Prompt Template:**

```
Isometric game tile, 512x256 pixels, painted 2D style, top-down isometric
perspective, [VARIANT], transparent background outside diamond, deep blue
ocean water, palette from deep navy #1a4f7a to bright aqua #5aacd4,
top-left lighting, no borders, seamless game asset, high detail
```

Replace `[VARIANT]` with each row description above.

---

### File 2: `tiles_sand.png` — Desert / Beach

**Palette:**

| Swatch | Hex | Role |
|--------|-----|------|
| Warm tan | `#d4a853` | Base sand |
| Ochre | `#b8854a` | Shadow tones |
| Golden highlight | `#f2dea0` | Light areas |
| Dry earth | `#a87040` | Cracked areas |
| Pebble grey | `#c8b89a` | Stone accents |

**10 Variants:**

| Row | Col 0 | Col 1 |
|-----|-------|-------|
| 0 | Smooth flat sand | Smooth sand, faint ripple |
| 1 | Wind-rippled sand | Rippled with tiny shadow lines |
| 2 | Coarse sand with pebbles | Sandy gravel mix |
| 3 | Cracked dry earth | Cracked earth, deep fissures |
| 4 | Mixed sand and gravel | Dry soil with stone fragments |

**AI Prompt Template:**

```
Isometric game tile, 512x256 pixels, painted 2D style, top-down isometric
perspective, [VARIANT], transparent background outside diamond, warm desert
sand tile, palette golden tan #d4a853 to ochre #b8854a, top-left lighting,
no borders, seamless game asset
```

---

### File 3: `tiles_plains.png` — Grassland / Meadow

**Palette:**

| Swatch | Hex | Role |
|--------|-----|------|
| Lush grass | `#5a9e3b` | Main fill |
| Bright grass | `#6ab846` | Highlights |
| Pale grass | `#79cc55` | Lit areas |
| Dry patch | `#a09444` | Bare earth accents |
| Flower yellow | `#f5c842` | Accent only (max 5% coverage) |

**10 Variants:**

| Row | Col 0 | Col 1 |
|-----|-------|-------|
| 0 | Short lush grass | Short grass, subtle variation |
| 1 | Medium grass clumps | Medium grass with bare patches |
| 2 | Patchy grass, some bare earth | Sparse grass, earth visible |
| 3 | Dense thick grass tufts | Thick grass, darker center |
| 4 | Grass with tiny wildflower hints | Grass with clover/daisy accents |

**AI Prompt Template:**

```
Isometric game tile, 512x256 pixels, painted 2D style, top-down isometric
perspective, [VARIANT], transparent background outside diamond, vibrant
green meadow grass tile, palette lime #6ab846 to golden #a09444,
top-left lighting, no borders, seamless game asset
```

---

### File 4: `tiles_forest.png` — Forest Floor

**Palette:**

| Swatch | Hex | Role |
|--------|-----|------|
| Dark canopy floor | `#1e3d14` | Shadow fill |
| Forest green | `#2d5a1f` | Main fill |
| Mid green | `#3a6b28` | Moss highlights |
| Leaf brown | `#5e4a2c` | Leaf litter |
| Root tan | `#7a6040` | Root/bark accents |

**10 Variants:**

| Row | Col 0 | Col 1 |
|-----|-------|-------|
| 0 | Dark mossy ground | Mossy ground, dappled light |
| 1 | Autumn leaf litter | Dense leaf cover |
| 2 | Tree roots and undergrowth | Exposed roots network |
| 3 | Forest debris and twigs | Dense twig and debris mix |
| 4 | Mixed moss and dark soil | Moss patches on dark earth |

**AI Prompt Template:**

```
Isometric game tile, 512x256 pixels, painted 2D style, top-down isometric
perspective, [VARIANT], transparent background outside diamond, dark forest
floor tile, palette deep forest green #1e3d14 to earthy brown #5e4a2c,
dappled top-left lighting through canopy, no borders, seamless game asset
```

---

### File 5: `tiles_mountain.png` — Rocky Highlands

**Palette:**

| Swatch | Hex | Role |
|--------|-----|------|
| Dark rock | `#484848` | Shadow fill |
| Slate grey | `#787878` | Main fill |
| Mid stone | `#909090` | Surface texture |
| Light stone | `#a8a8a8` | Highlights |
| Snow | `#e8f0ff` | Snow patches (rows 3–4 only) |

**10 Variants:**

| Row | Col 0 | Col 1 |
|-----|-------|-------|
| 0 | Flat granite surface | Granite with hairline cracks |
| 1 | Rocky ground with cracks | Cracked stone, deep fissures |
| 2 | Gravel and small stones | Mixed gravel and boulders |
| 3 | Stone with snow patches | Snow-dusted rock |
| 4 | Heavy snow on rock | Mixed rock and snow |

**AI Prompt Template:**

```
Isometric game tile, 512x256 pixels, painted 2D style, top-down isometric
perspective, [VARIANT], transparent background outside diamond, grey rocky
mountain tile, palette slate grey #787878 to near-white snow #e8f0ff,
top-left lighting, no borders, seamless game asset
```

---

## Environmental Components (Separate Overlay Sheets)

These go on a second TileMap layer over the base terrain:

| Component | Sheet Name | Description |
|-----------|-----------|-------------|
| Coastline edge | `tiles_env_coast.png` | Water→Sand border (shoreline foam) |
| Cliff face | `tiles_env_cliff.png` | Mountain→Plains vertical drop |
| Forest edge | `tiles_env_treeline.png` | Dense canopy border |

These require a blob tile set (47 variants per component) for seamless edges.
See the Wang tile reference: boristhebrave.com/2021/04/25/wang-tiles/

---

## Industry Standard Asset Sources

| Source | License | Notes |
|--------|---------|-------|
| kenney.nl/assets | CC0 | Free isometric packs, individual PNGs — pack with TexturePacker |
| opengameart.org | CC0/CC-BY | Search "isometric tileset" |
| craftpix.net | Commercial | High quality, $5–30 |
| itch.io | Mixed | Many options $0–15 |

For Godot TileSet Terrain auto-transitions, a full blob set needs **47 tiles per biome**.
Reference: docs.godotengine.org — Using Tilemaps (Terrain section)

---

## Validation Checklist Before Importing to Godot

- [ ] Image is exactly **1024 × 1280 pixels**
- [ ] Exactly 10 tiles visible in grid preview (2 cols × 5 rows)
- [ ] Diamond area filled with color, outside diamond fully transparent (alpha = 0)
- [ ] No dark halo around edges (export with **straight alpha**, NOT premultiplied)
- [ ] Each biome sheet visually distinct without color grading
- [ ] Consistent light direction (top-left) within each sheet
- [ ] Light direction consistent across all 5 biome sheets
- [ ] File saved as PNG-32 (RGBA, not indexed/palette mode)
