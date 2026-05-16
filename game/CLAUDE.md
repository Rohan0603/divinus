# Divinus — Godot Frontend Development Guide

**Godot 4.6 god game · GDScript · Top-down 2D**

## Quick Setup

**Launch Godot:**
```bash
# If godot is in PATH:
godot --path "C:\project!!\divinus\game"

# Or manually:
# 1. Open Godot Editor
# 2. Open project at: C:\project!!\divinus\game\project.godot
```

**Rendering:** Project set to `gl_compatibility` (OpenGL) for broad compatibility.

**Dependencies:**
- ✅ Godot 4.6.2+ (download: https://godotengine.org)
- ✅ Backend (optional) — for real NPC dialogue via HTTP
- ✅ GDScript (built-in to Godot)

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

## Backend Integration (LLM Dialogue)

### Overview
NPC dialogue is generated by a **FastAPI backend** with optional **Ollama LLM** support:

- **Mock Mode** (default): 10 deterministic responses, instant, no GPU needed
- **LLM Mode**: AI-generated unique dialogue, ~2.2s response time

### Backend API
**Endpoint:** `POST http://localhost:8000/npc/dialogue`

**Request:**
```json
{
  "npc_id": 1,
  "state": "witness",
  "boon_cast": "heal",
  "day": 1
}
```

**Response:**
```json
{
  "dialogue": "My ailments vanish! Surely the divine walks among us!",
  "faith_bonus": 15
}
```

### Setup Backend

**1. Install dependencies:**
```bash
cd ../backend
pip install -r requirements.txt
```

**2. Run in Mock Mode (no Ollama):**
```bash
USE_MOCK=true python main.py
# Server starts at http://localhost:8000
```

**3. Run in LLM Mode (with Ollama):**
```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Set config in backend/.env
# USE_MOCK=false

# Start backend
python main.py
```

**4. Test backend:**
```bash
curl -X GET http://localhost:8000/health
curl -X POST http://localhost:8000/npc/dialogue \
  -H "Content-Type: application/json" \
  -d '{"npc_id": 1, "state": "witness", "boon_cast": "heal", "day": 1}'
```

### Calling Backend from GDScript
```gdscript
# In npc.gd or similar
func _request_dialogue(state: String, boon: String, day: int) -> void:
    var url = "http://localhost:8000/npc/dialogue"
    var body = JSON.stringify({
        "npc_id": id,
        "state": state,
        "boon_cast": boon,
        "day": day
    })
    
    var request = HTTPRequest.new()
    add_child(request)
    request.request_completed.connect(_on_dialogue_response)
    request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_dialogue_response(result, response_code, headers, body):
    if response_code == 200:
        var json = JSON.parse_string(body.get_string_from_utf8())
        dialogue = json["dialogue"]
        faith_bonus = json["faith_bonus"]
```

### Performance Notes
- **Mock mode:** <50ms per request
- **LLM mode:** ~2.2s per request (Ollama phi3:mini on NVIDIA GPU)
- Dialogue generation is **non-blocking** — use HTTPRequest callback

### For MVP
You don't *need* the backend. Without it:
- Use mock responses directly in `npc.gd`
- Same dialogue pool, instant
- Switch to backend later by replacing the dialogue getter

---

## Post-MVP Ideas

- Rival god AI steals followers
- Follower happiness meter (decays without boons)
- Multiple biomes unlocked at level thresholds
- Procedurally generated TileMap
- NPC personality variants (doubter, zealot, trader)
- Sandbox mode (remove 15-day limit)
- ✅ **NPC dialogue via local LLM (Ollama + phi3:mini)** — *Backend ready*
- Achievement system (subscribe to EventBus)
- Quest system (same EventBus pattern)

---

## References

**Full GDD:** `divinus_gdd.md`

**Backend:** `../backend/README.md` (API, testing, config)

**Inspiration Games:**
- Black & White (2001) — boon feedback loop
- Reus (2013) — indie-scale follower systems
- Populous (1989) — original god game simplicity

**Godot Docs:** https://docs.godotengine.org  
**GDQuest:** Free top-down 2D tutorials  
**KidsCanCode:** Beginner-friendly Godot series  

---

*Start with Phase 2 (TileMap). Phases 1 autoloads are already built.*
