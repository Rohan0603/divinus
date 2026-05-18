# Divinus — Godot Frontend Development Guide

**Godot 4.6 god game · GDScript · Top-down 2D**

---

## Quick Setup

**Launch Godot (Testing):**
```bash
# Quick console-based testing (minimal UI, full logging)
"C:\Users\leoZblack\Desktop\Godot_v4.6.2-stable_win64_console.exe" --path "C:\project!!\divinus\game"
```

**Launch Godot (Editor):**
```bash
# Or open game/project.godot directly in Godot Editor for interactive development
```

**Rendering:** `gl_compatibility` (OpenGL) — keep this renderer.

**Dependencies:**
- Godot 4.6.2+
- Godot AI plugin (already installed — enables live MCP editor control)
- Backend (optional) — LLM NPC dialogue via HTTP

---

## Godot AI MCP — Live Editor Integration

The **Godot AI** plugin is installed and Claude Code is connected at `http://127.0.0.1:8000/mcp`.

**Requirements for MCP to work:**
1. Godot editor must be open with the Godot AI plugin enabled
2. The plugin auto-starts its Python server on port 8000
3. Verify with: `curl http://127.0.0.1:8000/mcp` (should return JSON)

**Key tools to use every session:**

| Tool | Purpose |
|------|---------|
| `project_run` | Run the game scene |
| `logs_read` | Read engine output / GDScript errors |
| `editor_screenshot` | See current editor/game state |
| `scene_get_hierarchy` | Inspect the live scene tree |
| `node_create` / `node_set_property` | Create/modify nodes |
| `script_patch` | Patch a script live in the editor |
| `scene_open` | Open a scene file |
| `editor_reload_plugin` | Reload a plugin |

**Typical debug loop:**
1. Edit `.gd` files with normal file tools
2. Call `project_run` to run the scene
3. Call `logs_read` to check for errors or print output
4. Call `editor_screenshot` to see the game visually
5. Repeat

**Important:** MCP tools connect to the *running* Godot editor instance. If Godot is closed, tools will fail. Always confirm Godot is open before using MCP tools.

---

## Architecture Overview

### Autoloads (Singletons) — registered in project.godot

| File | Purpose |
|------|---------|
| `autoloads/GodStats.gd` | God stats: followers, divine_power, god_level, role_counts, shrine tracking |
| `autoloads/EventBus.gd` | Global signal hub: boon_cast, npc_converted, shrine_unlocked, shrine_site_placed, day_changed, etc. |
| `autoloads/DayClock.gd` | 1 in-game day = 180 real seconds. Emits day_changed + day_ending (30s warning) |
| `autoloads/EnemySpawner.gd` | Reads WAVE_TABLE on day_ending, spawns bandits from map edges |

### Scene Hierarchy

| Scene | Root type | Script | Purpose |
|-------|-----------|--------|---------|
| `Main.tscn` | Node2D | `main.gd` | World root. Spawns 6 NPCs, handles boon casting and shrine placement |
| `NPC.tscn` | CharacterBody2D | `NPC.gd` | Full NPC — 6 states + 5 roles + skill system |
| `HUD.tscn` | CanvasLayer | `HUD.gd` | Divine Power bar, follower count, level, day timer |
| `Shrine.tscn` | StaticBody2D | `Shrine.gd` | Built shrine — generates 10 DP/5s |
| `ShrineConstructionSite.tscn` | Node2D | `ShrineConstructionSite.gd` | Yellow placeholder — needs 3 builders for 5s to complete |
| `Boon.tscn` | Area2D | `boon.gd` | Click-to-cast divine manifestation, radius 200px |
| `Enemy.tscn` | CharacterBody2D | `enemy.gd` | Bandit — hunts nearest follower, exits after contact |

### NPC State Machine (NPC.gd)

States transition: **Unaware → Witness → Follower role**

**Pre-conversion states:**
- **Unaware** (blue) — random wander; triggered by `witness_miracle()` or boon proximity
- **Witness** (yellow) — stationary, faith accumulates at 3/s; converts at threshold 10

**Post-conversion roles** (first follower always becomes Head Preacher):

| Color | Role | Behavior | Income |
|-------|------|---------|--------|
| Golden | HeadPreacher | Hunts unaware NPCs → calls `witness_miracle()` at range 32px → finds next | — |
| Orange | Builder | Walks to nearest construction site, calls `builder_arrived()` on arrival | — |
| Teal | Gatherer | Wanders randomly | 3 DP / 5s |
| Yellow-green | Farmer | Orbits nearest shrine (40–80px radius) | 4 DP / 5s |
| Red | Defender | Chases nearest enemy, calls `enemy.start_exit()` at 40px range | — |
| Deep purple | Scholar | Drifts to nearest shrine, stays within 48px | 2.5 DP / 5s |

**Skill system:** Each income-generating role earns 10 XP per tick. At 100 XP → level up (max 5). Efficiency = `1.0 + skill_level / 5.0` (1.0× to 2.0×).

**Role assignment priority** (`GodStats.assign_role()`):
1. Builder — until `role_counts["Builder"] >= shrine_sites_pending * 3`
2. Defender — if enemies exist and defenders < 2
3. Farmer — if shrines_built > 0 and farmers < shrines_built * 2
4. Scholar — if shrines_built > 0 and scholars < shrines_built
5. Gatherer — default

### Key Signal Flow

```
Left-click → main.gd._input → spend 5 DP → Boon.tscn instantiated
  └─ Boon._ready → EventBus.boon_cast.emit({}, position)
       └─ NPC._on_boon_cast → witness_miracle() [if Unaware and within 200px]

NPC faith >= 10 → _become_follower
  └─ GodStats.add_follower → shrine_unlocked.emit() [every 5 followers]
       └─ main.gd._on_shrine_unlocked → ShrineConstructionSite spawned
  └─ EventBus.npc_converted.emit(npc)
       └─ main.gd._on_npc_converted → first one gets assign_head_preacher()

3 builders hold ShrineConstructionSite for 5s → shrine_completed.emit()
  └─ main.gd._on_shrine_completed → Shrine.tscn spawned, GodStats.on_shrine_built()

Shrine._ready → Timer 5s → GodStats.add_divine_power(10.0)

DayClock 150s → day_ending → EnemySpawner._on_day_ending → bandits spawn
DayClock 180s → day_changed → EnemySpawner._on_day_changed → stragglers exit
```

---

## File Structure

```
game/
├── project.godot              ← autoload registration (EventBus, GodStats, DayClock, EnemySpawner)
├── autoloads/
│   ├── GodStats.gd            ← followers, divine_power, role_counts, shrine tracking
│   ├── EventBus.gd            ← all signals
│   ├── DayClock.gd            ← 180s day timer + 150s raid warning
│   └── EnemySpawner.gd        ← WAVE_TABLE, spawns from edges on day_ending
├── scenes/
│   ├── Main.tscn + main.gd    ← world root, NPC/shrine/boon spawning
│   ├── NPC.tscn + NPC.gd      ← full NPC: 6 states, 5 roles, skill system
│   ├── HUD.tscn + HUD.gd      ← UI labels wired to GodStats signals
│   ├── Shrine.tscn + Shrine.gd
│   ├── ShrineConstructionSite.tscn + ShrineConstructionSite.gd
│   ├── Boon.tscn + boon.gd
│   └── Enemy.tscn + enemy.gd
└── resources/                 ← (future: boon data, wave configs, tile data)
```

---

## Build Order Status

1. ✅ **Autoloads** — GodStats, EventBus, DayClock, EnemySpawner
2. ✅ **TileMap world** — isometric dungeon dirt tiles (E/N/S/W directional variants with biome tinting)
3. ✅ **NPC wandering** — CharacterBody2D movement to random points
4. ✅ **Click-to-cast boon** — left click, costs 5 DP, Area2D radius 200px
5. ✅ **NPC conversion** — faith threshold → role assignment → colored sprite
6. ✅ **Shrine construction** — 3 builders hold site 5s → Shrine spawns
7. ✅ **Shrine + energy** — Shrine Timer → `GodStats.add_divine_power(10)` every 5s
8. ✅ **HUD** — CanvasLayer labels reacting to GodStats/DayClock signals
9. ✅ **Head Preacher** — first follower auto-converts unaware NPCs
10. ✅ **Role system** — 5 roles with skill progression
11. ✅ **DayClock + day counter** — HUD shows day and time remaining
12. ✅ **Enemy spawner** — wave table, bandits spawn on day_ending
13. ✅ **Game over condition** — followers == 0 → game_over signal
14. ✅ **Win condition** — survive day 15 with more followers than rival → win screen with restart
15. ✅ **Rival god agents** — spawns day 6, casts boons, competes for followers

---

## Polish & Optimization (Completed)

1. ✅ **Smooth Camera Following** — Camera eases to player position over 0.3s with TRANS_CUBIC easing
2. ✅ **Enhanced Boon Ring Animation** — Boons pulse scale (0.8x–1.2x) continuously with sine wave easing
3. ✅ **Shrine Completion Celebration** — 50-particle burst + white screen flash on completion
4. ✅ **NPC Knockback Feedback** — NPCs knocked back 300px/s away from enemy on hit
5. ✅ **HUD Polish** — Font size 24pt, labels stacked in VBoxContainer

---

## Core Systems

### Win / Fail
- **Win:** Day 15 reached AND player has more followers than rival → "YOU WIN!" screen (restart resets all state)
- **Fail (Followers):** Followers reach 0 → `GodStats.game_over` → game over screen (restart resets all state)
- **Fail (Rival):** Day 15 reached AND rival has ≥ followers → `GodStats.game_over` → game over

### Divine Power Economy
| Source | Rate |
|--------|------|
| Starting | 20 DP |
| Boon cast | -5 DP |
| Shrine | +10 DP / 5s |
| Gatherer (base→max) | +3–6 DP / 5s |
| Farmer (base→max) | +4–8 DP / 5s |
| Scholar (base→max) | +2.5–5 DP / 5s |

### Shrine Construction Pipeline
1. Every 5 followers → `shrine_unlocked` → ShrineConstructionSite placed at random position
2. NPC role assignment returns "Builder" until `3 * shrine_sites_pending` builders exist
3. Builders walk to site, call `builder_arrived()` on contact
4. 3 builders present for 5s → `shrine_completed` → Shrine.tscn replaces site
5. `GodStats.on_shrine_built()` → `shrine_sites_pending--`, `shrines_built++`

### Enemy Raids
- 30s before each day ends → `day_ending` → EnemySpawner checks WAVE_TABLE
- Bandits spawn on map edges, hunt nearest NPC in "followers" group
- Contact → `npc.take_damage()` → follower reverts to Unaware + bandit exits
- Day rollover → all remaining bandits exit

### Rival God System
- **Spawn:** First rival spawns day 6 (RivalSpawner). Second spawns day 11 if player has >10 followers
- **Mechanics:** Rival casts boons every 8 seconds (costs 20 DP); unaware NPCs within 200px convert to rival (turn cyan)
- **Win Condition:** Day 15 requires MORE followers than rival (not tied)
- **Tracking:** GodStats tracks `rival_followers`, `rival_divine_power`, `rival_shrines_built`
- **HUD:** Displays "Rival: X followers" to show competition progress
- **Logging:** [RivalGod], [RivalSpawner], [NPC] prefixes in console for debugging

---

## Development Guidelines

### Signals Over Polling
```gdscript
# GOOD
GodStats.followers_changed.connect(_on_followers_changed)

# BAD
if GodStats.followers > 10:
    update_ui()
```

### Groups Used
| Group | Who's in it | Purpose |
|-------|-------------|---------|
| `npcs` | All NPC instances | NPC-to-NPC queries (Head Preacher finds Unaware) |
| `followers` | Converted NPCs only | Enemy hunt targets |
| `shrines` | Built Shrine nodes | Farmer/Scholar navigation |
| `shrine_sites` | ShrineConstructionSite nodes | Builder navigation |
| `enemies` | Enemy instances | Defender navigation, GodStats.assign_role() check |

### Adding New Boon Types
Boons are instantiated at cursor on left-click (main.gd). To add a new boon:
1. Create a new .tscn extending Area2D
2. In its `_ready()`, emit `EventBus.boon_cast.emit(boon_data_dict, global_position)`
3. NPCs react in `_on_boon_cast` — extend that method to handle new boon types

### Adding New NPC Roles
1. Add a new `ROLE_COLORS` entry in NPC.gd
2. Add `_update_<role>(delta)` method
3. Add the role to the `match current_state` block
4. Add it to `GodStats.role_counts` and update `assign_role()` logic

---

## Testing with Godot AI MCP

With Godot open and the plugin active, Claude Code can interact directly:

```
# Run the game
project_run op="run"

# Read GDScript errors
logs_read

# Inspect current scene
scene_get_hierarchy path="/root/Main"

# Check NPC state in inspector
node_find name="NPC"

# Take screenshot to verify visuals
editor_screenshot
```

**Test checklist:**
1. 6 blue NPCs spawn and wander
2. Left click in game area → boon ring appears → nearby NPCs turn yellow
3. Yellow NPC faith fills → turns golden (HeadPreacher first, then colored roles)
4. Golden Head Preacher walks toward blue NPCs and converts them
5. At 5 followers → yellow square appears (construction site)
6. Orange NPCs walk to site and hold → after 5s → golden square (shrine)
7. Shrine generates DP (watch HUD Divine Power tick up)
8. After day 150s → red bandits appear from edges

---

## Backend Integration (LLM Dialogue)

**Endpoint:** `POST http://localhost:8000/npc/dialogue`

**Mock Mode (default, no GPU):**
```bash
cd ../backend
USE_MOCK=true python main.py
```

**LLM Mode (Ollama):**
```bash
ollama serve   # Terminal 1
python main.py # Terminal 2 (backend/.env: USE_MOCK=false)
```

---

## References

**Full GDD:** `divinus_gdd.md`
**Backend:** `../backend/README.md`
**Godot Docs:** https://docs.godotengine.org
**Godot AI Plugin:** https://github.com/hi-godot/godot-ai
