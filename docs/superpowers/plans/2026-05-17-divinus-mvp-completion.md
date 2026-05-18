# Divinus MVP Completion — TileMap & Rival Agents Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the divinus MVP by adding a grass/dirt terrain TileMap and rival god agents that spawn after day 6 to create competitive gameplay tension.

**Architecture:** 
- **TileMap:** Simple procedural terrain fill (grass with occasional dirt tiles) using a basic TileSet. Remove the plain ColorRect background and use Godot's native TileMap for proper tile-based world.
- **Rival Agents:** New `RivalGod` scene (similar to NPC but with independent divine power, boon-casting, and follower conversion). Spawns starting day 6. Tracks rival stats in GodStats alongside player stats.

**Tech Stack:** Godot 4.6 GDScript, TileSet resource, signal-driven events via EventBus.

---

## File Structure

**New Files:**
- `resources/terrain_tileset.tres` — TileSet with grass/dirt tiles
- `scenes/RivalGod.tscn` — Rival agent scene
- `scenes/rival_god.gd` — Rival agent behavior (boon casting, follower conversion)
- `autoloads/RivalSpawner.gd` — Manages rival god creation, stats, and lifecycle

**Modified Files:**
- `scenes/main.gd` — Handle terrain setup, wire rival spawner
- `scenes/Main.tscn` — Update TileMap node, hide ColorRect
- `autoloads/GodStats.gd` — Add rival god state tracking
- `autoloads/EventBus.gd` — Add rival_boon_cast signal
- `autoloads/NPC.gd` — Add rival boon conversion handler
- `project.godot` — Register RivalSpawner autoload

---

## Task 1: Create TileSet Resource

**Files:** Create `resources/terrain_tileset.tres`

Create a minimal TileSet resource. Godot will populate it via procedural fill in the terrain function.

---

## Task 2: Add Terrain Population to Main Scene

**Files:** Modify `scenes/main.gd`, `scenes/Main.tscn`

Add `_populate_terrain()` function to main.gd that fills the TileMap with grass/dirt tiles in a grid. Call it in `_ready()` before spawning NPCs. Update Main.tscn to assign the TileSet to the TileMap node and hide the ColorRect background.

---

## Task 3: Add Rival God Stats to GodStats

**Files:** Modify `autoloads/GodStats.gd`

Add tracking variables: `rival_divine_power`, `rival_followers`, `rival_shrines_built`. Add helper methods: `add_rival_divine_power()`, `add_rival_follower()`, `remove_rival_follower()`.

---

## Task 4: Add Rival Boon Signal to EventBus

**Files:** Modify `autoloads/EventBus.gd`

Add signal: `signal rival_boon_cast(boon_data: Dictionary, position: Vector2)`

---

## Task 5: Create RivalGod Scene

**Files:** Create `scenes/RivalGod.tscn`, `scenes/rival_god.gd`

Create a Node2D scene with a Timer. rival_god.gd script handles boon casting every 8 seconds when the rival has enough DP (20 DP per cast). Starts with 30 DP.

---

## Task 6: Create RivalSpawner Autoload

**Files:** Create `autoloads/RivalSpawner.gd`, modify `project.godot`, `scenes/main.gd`

Manage rival spawning on day_changed signal. First rival spawns on day 6. Register as autoload in project.godot. Update main.gd to call `RivalSpawner.set_world_root(self)` in _ready() after terrain setup.

---

## Task 7: Handle Rival Boons in NPC Conversion

**Files:** Modify `scenes/NPC.gd`

Add connection to `EventBus.rival_boon_cast` in _ready(). Add handler `_on_rival_boon_cast()` that converts unaware NPCs within 200px radius to rival followers (cyan color). Add `_become_rival_follower()` method that updates state and calls `GodStats.add_rival_follower()`.

---

## Task 8: Manual Testing & Iteration

**Files:** Test in editor

Run the game and verify: TileMap loads with grass/dirt, NPCs spawn on terrain, Win Screen mechanic from previous work, Rival spawns on day 6, Rival casts boons every 8s, NPCs convert to cyan when hit by rival boons, Game reaches day 15 and shows win screen with restart button.
