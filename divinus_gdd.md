# DIVINUS
## Game Design Document
**A Top-down 2D God Game · Godot 4 · GDScript**
Version 1.1 · 2026

> **Beginner Scope · Survival / Sim · Singleplayer**

*You are a newly awakened god. Nameless villagers roam a small world. They can sense your presence — and if you perform miracles, they worship you. More worshippers means more divine power, which unlocks new abilities. Your goal: build a devoted civilization and survive 15 days against mounting forces of darkness.*

---

## 1. Core Gameplay Loop

The loop below repeats throughout the game. Each cycle makes the god more powerful, which in turn makes the loop faster.

| Step | Action | Detail |
|------|--------|--------|
| **1** | **NPCs wander the map** | Simple AI — walk to random positions, idle near shrines. No worship yet. |
| **2** | **Player performs a boon** | Click anywhere to cast the selected boon. A radius determines which NPCs witness the miracle. |
| **3** | **NPCs convert to followers** | Witnesses gain faith points. Enough faith → follower state → they go build a shrine. |
| **4** | **Shrines generate divine energy** | Each shrine is a passive income source. Energy is the mana for casting boons. |
| **5** | **God levels up** | Total followers = XP. At thresholds, new boon types unlock and passive bonuses activate. |
| **6** | **Rival forces threaten followers** | Bandits (and later rival god agents) actively attack followers and shrines each day. Protect your flock to keep their faith. |

---

## 2. Win & Fail Conditions

| Condition | Detail |
|-----------|--------|
| **Win (MVP)** | Survive 15 in-game days |
| **Fail** | All followers drop to zero — god loses divine connection and fades |
| **Post-MVP** | Sandbox mode — no explicit end state, endless scaling |

---

## 3. Day & Night Cycle

- **1 in-game day = 3 real-time minutes**
- A `DayClock` autoload tracks elapsed time and emits a `day_changed(day_number)` signal at each transition
- Enemy waves spawn at the start of each new day, scaled by day number
- HUD displays current day and a progress bar for time remaining in the day
- Days 1–5: Bandit waves only
- Days 6–10: Bandits + rival god scouts
- Days 11–15: Full rival god assault — agents target shrines directly

---

## 4. Key Systems (MVP)

### 4.1 NPC State Machine

Every NPC cycles through exactly three states. Built as a proper **StateChart pattern** — new states (trader, priest, doubter) can be added in post-MVP without modifying core logic.

| States | Transitions |
|--------|-------------|
| **Unaware** → default wandering | Unaware → Witness: enters boon radius |
| **Witness** → saw a miracle, gaining faith | Witness → Follower: faith >= threshold |
| **Follower** → max faith reached, builds shrine | Follower → Unaware: faith drops to 0 (enemy damage) |

> **Scalability note:** Each state is a separate inner class implementing a `State` interface (`enter()`, `update()`, `exit()`). The NPC holds a reference to the current state and delegates to it. Adding a new state = new class, zero changes to existing states.

### 4.2 Boon Casting

The player interacts with the world entirely through boons. Click anywhere on the map to cast the currently selected boon. Boons are defined as **data Resources** (`BoonData.tres`) — adding a new boon requires no core script changes.

| Boon Properties | Player Feedback |
|----------------|-----------------|
| Energy cost (drained from GodStats) | Particle burst at cast location |
| Radius (Area2D collision shape size) | Affected NPCs glow briefly |
| Effect type (heal, grow, smite, etc.) | HUD energy bar drops visually |
| Cooldown (seconds before reuse) | Faith number floats above NPCs |

> **Scalability note:** A `BoonRegistry` autoload holds an `Array[BoonData]`. New boons are `.tres` resource files registered here — the casting system reads from the registry, never from hardcoded values.

### 4.3 God Stats (Autoload Singleton)

`GodStats.gd` holds all god power variables. Every meaningful change emits a signal — UI and systems **react to signals, never poll**.

| Variable | Type | Purpose |
|----------|------|---------|
| `followers` | int | Total active followers — primary XP metric |
| `divine_power` | float | Current divine energy available for casting |
| `max_divine_power` | float | Cap (100 at MVP) |
| `god_level` | int | Current level (1–6). Gates ability unlocks |
| `xp_thresholds` | Array[int] | Follower counts needed to reach each level |
| `shrines_built` | int | Completed shrines — drives Farmer/Scholar quotas |
| `shrine_sites_pending` | int | Sites placed but not yet built — drives Builder quota |
| `role_counts` | Dictionary | Per-role population: Builder, Gatherer, Farmer, Defender, Scholar |

**Signals emitted by GodStats:**
```
signal followers_changed(new_count: int)
signal divine_power_changed(new_value: float)
signal level_up(new_level: int)
signal game_over()
```

### 4.4 EventBus (Autoload Singleton)

A dedicated **EventBus.gd** autoload acts as a global signal hub. Systems communicate through the bus — no direct node references between unrelated systems.

```gdscript
# EventBus.gd — global signal hub
signal boon_cast(boon_data: Dictionary, position: Vector2)
signal npc_converted(npc: Node)
signal shrine_built(shrine: Node)
signal enemy_killed(enemy: Node)
signal day_changed(day_number: int)
signal day_ending(day_number: int)      # fires 30s before day end — triggers raids
signal wave_started(wave_config: Dictionary)
signal shrine_unlocked()               # fires every 5 followers
signal shrine_site_placed(site_position: Vector2)
signal npc_role_assigned(npc: Node, role: String)
```

> **Scalability note:** Any new system (quests, achievements, analytics) subscribes to EventBus signals without touching existing code.

### 4.5 Enemy Spawner & Day Config

Enemies are driven by a **day config table** — a data-driven `Array[Dictionary]` where each entry defines a day's wave. Tuning difficulty = editing data, not code.

```gdscript
# day_config.gd (or a JSON resource)
const WAVE_TABLE = [
    { "day": 1,  "bandits": 2,  "agents": 0 },
    { "day": 2,  "bandits": 3,  "agents": 0 },
    { "day": 5,  "bandits": 5,  "agents": 0 },
    { "day": 6,  "bandits": 4,  "agents": 1 },
    { "day": 10, "bandits": 6,  "agents": 3 },
    { "day": 11, "bandits": 5,  "agents": 5 },
    { "day": 15, "bandits": 8,  "agents": 8 },
]
```

Enemies actively hunt the **nearest follower or shrine** — they don't wander randomly.

---

## 5. God Progression & Abilities

| Level | Title | Ability | Description |
|-------|-------|---------|-------------|
| **1 — Awakening** | Heal | Restore NPC health | Starting boon. Low cost, teaches click-to-cast. |
| **2 — Known** | Bountiful Harvest | Grow crops nearby | Boosts follower happiness → faster faith gain. |
| **3 — Revered** | Divine Shield | Protect a follower group | Teaches defensive energy use against waves. |
| **4 — Feared** | Smite | Destroy an enemy instantly | AoE fear — nearby neutral NPCs convert witnessing the power. |
| **5 — Ascended** | Divine Beacon | Passive conversion aura | Placeable object — introduces placement strategy. |
| **6 — Omnipotent** | World Reshape | Alter terrain tiles | Remove obstacles, create holy ground. |

---

## 6. Map & Camera

- **Map:** Small single TileMap (grass + dirt tiles). One world for MVP.
- **Camera:** `Camera2D` with drag-to-scroll. No follow target — player pans freely.
- **Bounds:** Camera clamped to TileMap edges — no scrolling into void.
- **Post-MVP:** Multiple biomes unlocked at god level thresholds.

---

## 7. Godot Scene Structure

| Scene File | Root Node | Script | Responsibility |
|------------|-----------|--------|----------------|
| `Main.tscn` | Node2D | `main.gd` | Game loop, spawns 6 NPCs, handles boon casting and shrine placement |
| `NPC.tscn` | CharacterBody2D | `NPC.gd` | 8 states: Unaware, Witness, HeadPreacher, Builder, Gatherer, Farmer, Defender, Scholar |
| `ShrineConstructionSite.tscn` | Node2D | `ShrineConstructionSite.gd` | Yellow placeholder — needs 3 builders for 5s to complete |
| `Shrine.tscn` | StaticBody2D | `Shrine.gd` | Timer → add 10 divine_power every 5s |
| `Boon.tscn` | Area2D | `boon.gd` | Spawned at cursor, emits EventBus.boon_cast, fades out |
| `Enemy.tscn` | CharacterBody2D | `enemy.gd` | Hunts nearest follower, deals damage on contact, then exits |
| `HUD.tscn` | CanvasLayer | `HUD.gd` | Divine power label, follower count, level, day timer |
| `GodStats.gd` | Autoload | — | All god variables + signals |
| `EventBus.gd` | Autoload | — | Global signal hub |
| `DayClock.gd` | Autoload | — | 180s day timer, emits day_changed + day_ending (30s warning) |
| `EnemySpawner.gd` | Autoload | — | Reads WAVE_TABLE, spawns bandits on day_ending |

---

## 8. Build Order

Do not skip ahead. Each phase builds on the last. Playable from Phase 4.

| Phase | Status | Task |
|-------|--------|------|
| **1** | ✅ Done | GodStats + EventBus + DayClock + EnemySpawner autoloads |
| **2** | ⬜ Pending | TileMap world (currently a ColorRect placeholder) |
| **3** | ✅ Done | NPC wandering — CharacterBody2D + random wander targets |
| **4** | ✅ Done | Click-to-cast boon — costs 5 DP, Area2D radius 200px. **PLAYABLE.** |
| **5** | ✅ Done | NPC conversion — faith threshold → role assignment → colored Polygon2D |
| **6** | ✅ Done | Shrine construction — 3 builders × 5s → Shrine.tscn |
| **7** | ✅ Done | Shrine + divine power — Timer → `GodStats.add_divine_power(10)` every 5s |
| **8** | ✅ Done | HUD — Labels react to GodStats signals; day timer in `_process` |
| **9** | ✅ Done | Head Preacher — first follower auto-converts Unaware NPCs |
| **10** | ✅ Done | Role system — 5 roles with skill progression (up to 2× income) |
| **11** | ✅ Done | DayClock + day counter — 180s day, HUD shows day and time remaining |
| **12** | ✅ Done | Enemy spawner — WAVE_TABLE, bandits spawn on day_ending |
| **13** | ✅ Done | Game over — followers == 0 → game_over signal |
| **14** | ⬜ Pending | Win condition — survive day 15 → win screen |
| **15** | ⬜ Pending | Rival god agents — post-MVP |

---

## 9. Scope, Risks & Next Steps

### 9.1 What Is NOT in the MVP

- Story or dialogue — NPCs are anonymous
- Save / load system — session-based only
- Sound design — placeholder or silent
- Multiple biomes or maps
- Multiplayer
- Pixel art — colored rectangles for MVP

### 9.2 Common Beginner Pitfalls

| Pitfall | Avoidance |
|---------|-----------|
| **Scope creep** | Finish Phase 4 before adding anything new |
| **No autoload** | All shared state goes through GodStats / EventBus — never get_node() across scenes |
| **Art first** | Colored rectangles until Phase 12 |
| **Deep nesting** | Keep scene hierarchy flat — one level of instancing |
| **Polling state** | Always use signals. Never check a variable every frame when a signal can notify once |

### 9.3 Inspiration References

| Study These Games | Godot Resources |
|-------------------|-----------------|
| Black & White (2001) — boon feedback loop | docs.godotengine.org |
| Reus (2013) — indie-scale follower systems | GDQuest — free top-down 2D tutorials |
| Populous (1989) — original god game simplicity | KidsCanCode — beginner-friendly series |

### 9.4 Post-MVP Ideas (v1.2+)

- Rival god AI that steals followers actively
- Follower happiness meter that decays without boons
- Multiple biomes unlocked at god level thresholds
- Procedurally generated world using Godot's TileMap noise tools
- NPC personality variants (doubter, zealot, trader)
- Sandbox mode — remove 15-day win condition
- **NPC dialogue using local LLM (Ollama + phi3:mini/gemma3:1b)** — ties into existing stack
- Achievement system — subscribe to EventBus signals, no core changes needed
- Quest system — same EventBus pattern

---

*Start with the autoloads. Everything else follows.*

---
**Rohan Ponnanna · Bengaluru · 2026**
