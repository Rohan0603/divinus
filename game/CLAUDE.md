# Divinus — Development Guide

**Godot 4.6 god game · GDScript · Top-down 2D**

## Quick Setup

**Godot Executable:**
```powershell
C:\Users\ponna\OneDrive\Desktop\Godot_v4.6.2-stable_win64.exe
C:\Users\ponna\OneDrive\Desktop\Godot_v4.6.2-stable_win64_console.exe
```

**Project Path:** `C:\Users\ponna\Project\divinus\game`

**Launch with OpenGL (required for no-GPU machine):**
```powershell
& "C:\Users\ponna\OneDrive\Desktop\Godot_v4.6.2-stable_win64.exe" --path "C:\Users\ponna\Project\divinus\game" --rendering-driver opengl3
```

**Project Already Set to:** Rendering Method = `gl_compatibility` (OpenGL). No flag needed after first launch.

---

## Architecture Overview

### Autoloads (Singletons)
All global state flows through autoloads. **Never** use `get_node()` across scenes.

- **GodStats.gd** — god variables + signals (`followers_changed`, `energy_changed`, `level_up`, `game_over`)
- **EventBus.gd** — global signal hub (`boon_cast`, `npc_converted`, `shrine_built`, `enemy_killed`, `day_changed`, `wave_started`)
- **DayClock.gd** — 1 in-game day = 180 real seconds. Emits `day_changed(day_number)` on EventBus.

### Scene Hierarchy (MVP)
Keep scenes **flat** — max one level of instancing:

| Scene | Root | Purpose |
|-------|------|---------|
| **Main.tscn** | Node2D | World root. Spawns 5 NPCs, holds TileMap, runs game loop. |
| **NPC.tscn** | CharacterBody2D | StateChart: Unaware (wander) → Witness (pause) → Follower (walk to shrine). |
| **HUD.tscn** | CanvasLayer | Energy bar, follower count, day display. Wires to GodStats signals. |

### State Machine Pattern (NPC)
Each NPC has three states as **inner classes** with `enter()`, `update()`, `exit()` methods:
- **Unaware** — wander randomly until `witness_miracle()` is called
- **Witness** — freeze for 3 seconds, then convert
- **Follower** — walk to shrine, increment `GodStats.followers`

Transition via `npc.transition_to("StateName")`. Add new states as new inner classes without touching existing code.

---

## Build Order (from GDD)

**Do not skip ahead. Playable from Phase 4.**

1. ✅ **Autoloads** — GodStats, EventBus, DayClock
2. **TileMap world** — grass/dirt tiles (visual only)
3. **NPC wandering** — CharacterBody2D movement to random points
4. **Click-to-cast boon** — spawns Area2D at cursor, detects NPCs, adds faith
5. **NPC conversion** — faith threshold → sprite change → walk to shrine → spawn Shrine
6. **Shrine + energy** — Shrine Timer → `GodStats.energy += amount` every N seconds
7. **HUD** — CanvasLayer with Labels reacting to GodStats signals
8. **Level-up & unlock** — followers cross threshold → `god_level++` → unlock next boon
9. **DayClock + day counter** — HUD shows current day + time remaining in day
10. **Enemy spawner** — reads wave table on `day_changed`, spawns bandits
11. **Game over condition** — followers == 0 → game over screen
12. **Win condition** — survive day 15 → win screen
13. **Rival god agents** — RivalAgent spawns from day 6, targets shrines

---

## Core Systems (MVP)

### Win / Fail
- **Win:** Survive 15 in-game days
- **Fail:** Followers reach 0 (game_over signal)

### God Progression
| Level | Boon | Effect |
|-------|------|--------|
| 1 | Heal | Restore NPC health (starting boon) |
| 2 | Bountiful Harvest | Grow crops → faster faith gain |
| 3 | Divine Shield | Protect followers from attacks |
| 4 | Smite | Destroy enemy, fear nearby NPCs |
| 5 | Divine Beacon | Placeable passive conversion aura |
| 6 | World Reshape | Alter terrain |

### Day & Night Cycle
- **1 in-game day = 180 real seconds**
- Days 1–5: Bandit waves only
- Days 6–10: Bandits + rival god scouts
- Days 11–15: Full rival god assault

### Boons
Boons are **data Resources** (`BoonData.tres`). Each boon defines:
- Energy cost
- Radius (Area2D detection)
- Effect type
- Cooldown

A `BoonRegistry` autoload holds all boons. Adding a new boon = new `.tres` file + registry entry. **Zero core code changes.**

---

## Development Guidelines

### Signals Over Polling
Always use signals. Never write:
```gdscript
# BAD
if GodStats.followers > 10:
    update_ui()
```

Instead:
```gdscript
# GOOD
GodStats.followers_changed.connect(_on_followers_changed)
func _on_followers_changed(new_count: int):
    update_ui()
```

### Flat Scene Hierarchy
Max one level of instancing. Avoid deep nesting:
```
✓ Main.tscn
  - NPC.tscn (instance)
  - HUD.tscn (instance)

✗ Main.tscn
  - World (Node2D)
    - Enemies (Node2D)
      - Bandit.tscn (instance)  ← too deep
```

### State Machine (Inner Classes)
Every state is a separate inner class. Add new states without modifying old ones:
```gdscript
class BaseState:
    var host
    func enter(): pass
    func update(delta): pass
    func exit(): pass

class NewState extends BaseState:
    # implement enter(), update(), exit()
```

### No Hardcoded Values in Code
Difficulty curves → wave table (data)
Boon stats → BoonData resources
NPC speeds → scene properties or constants at top of script

### EventBus Everywhere
Any system that affects others must emit to EventBus. Never direct node references:
```gdscript
# BAD
NPC.faith += 10
Main.update_hud()

# GOOD
EventBus.npc_converted.emit(npc)
# Listeners on EventBus increment followers, update HUD
```

---

## File Structure

```
game/
├── project.godot              ← autoload registration, renderer settings
├── autoloads/
│   ├── GodStats.gd
│   ├── EventBus.gd
│   └── DayClock.gd
├── scenes/
│   ├── Main.tscn
│   ├── NPC.tscn
│   └── HUD.tscn
├── scripts/
│   ├── main.gd
│   ├── npc.gd
│   └── hud.gd
└── resources/
    └── (boon data, wave configs, tile data — post-MVP)
```

---

## Testing the Setup

1. **Launch Godot** with the command above or open `game/project.godot` directly
2. **Play** — five green NPCs should spawn and wander
3. **Test NPC conversion** in the **Debugger Console**:
   ```gdscript
   get_tree().get_first_child_in_group("npc").witness_miracle()
   ```
   Watch follower count tick up in HUD.

---

## Post-MVP Ideas

- Rival god AI steals followers
- Follower happiness meter (decays without boons)
- Multiple biomes unlocked at level thresholds
- Procedurally generated TileMap
- NPC personality variants (doubter, zealot, trader)
- Sandbox mode (remove 15-day limit)
- **NPC dialogue via local LLM (Ollama + phi3/gemma)**
- Achievement system (subscribe to EventBus)
- Quest system (same EventBus pattern)

---

## References

**Full GDD:** `C:\Users\ponna\Project\divinus\divinus_gdd.md`

**Inspiration Games:**
- Black & White (2001) — boon feedback loop
- Reus (2013) — indie-scale follower systems
- Populous (1989) — original god game simplicity

**Godot Docs:** docs.godotengine.org
**GDQuest:** Free top-down 2D tutorials
**KidsCanCode:** Beginner-friendly Godot series

---

*Start with Phase 2 (TileMap). Phases 1 autoloads are already built.*
