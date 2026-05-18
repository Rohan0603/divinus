# Kenney Dungeon Assets Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the programmatic kenney tile terrain with the imported `game/Angle/` dungeon asset pack and scatter decorative props (barrels, chests, columns) across the world, then validate visually via MCP.

**Architecture:** The existing `_populate_terrain()` in `main.gd` already loads 256×512 PNGs and resizes them to 64×128 for a `TILE_SHAPE_ISOMETRIC` TileMap — we swap the source paths to `Angle/` tiles. A new `_spawn_dungeon_props()` method places `Sprite2D` nodes for props; Y-sort is already enabled on Main so they layer with NPCs automatically.

**Tech Stack:** Godot 4.6.2, GDScript, Godot AI MCP (for run + screenshot validation), Kenney Isometric Miniature Dungeon pack (`game/Angle/` — 256×512 PNGs)

---

## File Map

| File | Change |
|------|--------|
| `game/scenes/main.gd` | Modify `_populate_terrain()` — swap tile paths to `Angle/`; add `_spawn_dungeon_props()` |

No new files needed.

---

### Task 1: Swap floor tiles to Kenney dungeon pack

**Files:**
- Modify: `game/scenes/main.gd:106-141`

The current `_populate_terrain()` loads three tiles from `resources/tiles/`. Replace those with three tiles from `Angle/`: `dirtTiles_S.png` (main floor), `stoneTile_S.png` (accent), `planks_S.png` (variant). All are 256×512 — the existing resize-to-64×128 logic stays identical. Only the paths change.

- [ ] **Step 1: Edit the paths array in `_populate_terrain()`**

In `game/scenes/main.gd`, replace lines 106–111:

```gdscript
# Before:
var paths := [
    "res://resources/tiles/kenney_dirt.png",
    "res://resources/tiles/kenney_dirtTiles.png",
    "res://resources/tiles/kenney_stone.png",
]

# After:
var paths := [
    "res://Angle/dirtTiles_S.png",
    "res://Angle/stoneTile_S.png",
    "res://Angle/planks_S.png",
]
```

- [ ] **Step 2: Update tile distribution weights to match dungeon aesthetic**

In `_populate_terrain()`, find the rng weight block (lines 132–140) and update:

```gdscript
# Before:
var source_id: int
if rng < 0.10:
    source_id = 2  # stone accent
elif rng < 0.30:
    source_id = 0  # plain dirt
else:
    source_id = 1  # dirtTiles (main)

# After:
var source_id: int
if rng < 0.08:
    source_id = 2  # planks accent (rare wooden floor sections)
elif rng < 0.25:
    source_id = 1  # stone tile (carved stone patches)
else:
    source_id = 0  # dirtTiles (main dungeon floor)
```

- [ ] **Step 3: Commit**

```bash
git add game/scenes/main.gd
git commit -m "feat: use kenney dungeon floor tiles (dirtTiles, stoneTile, planks)"
```

---

### Task 2: Scatter dungeon props

**Files:**
- Modify: `game/scenes/main.gd` — add `_spawn_dungeon_props()` and call it from `_ready()`

Props are `Sprite2D` nodes placed at world positions. The Main node already has `y_sort_enabled = true` so props automatically sort behind/in-front of NPCs by Y coordinate. Props use the 256×512 source textures scaled down to a readable size.

The playable diamond covers approximately X: 215–810, Y: 120–500 (derived from NPC spawn bounds). Props are placed only in that region and must not sit on top of each other — use a simple minimum-distance guard.

- [ ] **Step 1: Add `_spawn_dungeon_props()` at the bottom of `main.gd`**

Append this method to `game/scenes/main.gd` (after `_populate_terrain()`):

```gdscript
func _spawn_dungeon_props() -> void:
    const PROP_SCALE := Vector2(0.18, 0.18)  # 256px -> ~46px wide on screen
    const PROP_TEXTURES := [
        "res://Angle/barrel_S.png",
        "res://Angle/barrelsStacked_S.png",
        "res://Angle/chestClosed_S.png",
        "res://Angle/stoneColumn_S.png",
        "res://Angle/stoneColumnWood_S.png",
    ]
    const NUM_PROPS := 22
    const MIN_DIST := 60.0

    var placed: Array[Vector2] = []

    for _i in range(NUM_PROPS):
        var tex_path := PROP_TEXTURES[randi() % PROP_TEXTURES.size()]
        var tex := load(tex_path) as Texture2D
        if tex == null:
            continue

        var pos := Vector2.ZERO
        var attempts := 0
        while attempts < 20:
            pos = Vector2(randf_range(240.0, 790.0), randf_range(140.0, 480.0))
            var too_close := false
            for p in placed:
                if pos.distance_to(p) < MIN_DIST:
                    too_close = true
                    break
            if not too_close:
                break
            attempts += 1

        if attempts >= 20:
            continue

        placed.append(pos)
        var sprite := Sprite2D.new()
        sprite.texture = tex
        sprite.scale = PROP_SCALE
        sprite.position = pos
        add_child(sprite)
```

- [ ] **Step 2: Call `_spawn_dungeon_props()` from `_ready()`**

In `main.gd`, find `_ready()` and add the call after `_populate_terrain()`:

```gdscript
func _ready() -> void:
    self.y_sort_enabled = true
    RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.08))
    _camera = $Camera2D
    _camera.make_current()
    EventBus.shrine_unlocked.connect(_on_shrine_unlocked)
    EventBus.npc_converted.connect(_on_npc_converted)
    EventBus.day_ending.connect(_on_day_ending)
    EventBus.enemy_spawned.connect(_on_enemy_spawned)
    EventBus.day_won.connect(_on_day_won)
    GodStats.game_over.connect(_on_game_over)
    _populate_terrain()
    _spawn_dungeon_props()      # <- add this line
    RivalSpawner.set_world_root(self)
    _spawn_npcs()
```

- [ ] **Step 3: Commit**

```bash
git add game/scenes/main.gd
git commit -m "feat: scatter dungeon props (barrels, chests, columns) with y-sort"
```

---

### Task 3: Run and visually validate via MCP

**Files:** None — validation only.

- [ ] **Step 1: Run the game**

Use MCP `project_run` tool with the main scene. Wait ~3 seconds for the engine to initialize.

- [ ] **Step 2: Read logs for errors**

Use `logs_read`. Expected output: no GDScript errors. Verify these lines do NOT appear:
- `Invalid get index 'texture'`
- `res://Angle/ — not found`
- `Null instance`

If any appear, the tile or prop path is wrong. Fix the path in `main.gd` and re-run.

- [ ] **Step 3: Take screenshot**

Use `editor_screenshot`. Verify:
1. Floor is covered with dungeon tiles (brownish/stone texture — not solid green or gray)
2. Scattered props (barrels, chests, columns) are visible
3. 6 blue NPC squares appear in front of or behind props by Y-position (Y-sort working)
4. HUD elements (Divine Power, follower count) are visible in the corners

- [ ] **Step 4: Confirm NPC movement is unaffected**

Wait 5 seconds and take a second screenshot. NPC positions should have shifted. Props should remain stationary. If NPCs are frozen, verify `_spawn_npcs()` is still called after `_spawn_dungeon_props()` in `_ready()`.

- [ ] **Step 5: Commit validation note**

```bash
git commit --allow-empty -m "validate: kenney dungeon asset integration confirmed via MCP screenshot"
```

---

## Self-Review

### Spec coverage
- Floor tiles swapped to `Angle/` dungeon pack
- Props scattered across the playable area
- Y-sort preserved (no changes needed — already enabled on Main)
- Existing gameplay untouched — only terrain/prop spawning changed
- Test + validate via MCP run + screenshot

### Placeholder scan
No TBD, TODO, or vague steps. All `res://Angle/` paths correspond to imported assets confirmed present by glob.

### Type consistency
`Sprite2D`, `Texture2D`, `Vector2` — standard Godot 4 types. `PROP_SCALE` defined once at the top of `_spawn_dungeon_props()`. Paths in Tasks 1 and 2 reference the same `res://Angle/` root consistently.
