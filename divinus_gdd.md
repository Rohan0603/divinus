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
| `energy` | float | Current divine energy available for casting |
| `max_energy` | float | Cap that grows with god level |
| `god_level` | int | Current level (1–6). Gates ability unlocks |
| `xp_thresholds` | Array[int] | Follower counts needed to reach each level |

**Signals emitted by GodStats:**
```
signal followers_changed(new_count)
signal energy_changed(new_value)
signal level_up(new_level)
signal game_over()
```

### 4.4 EventBus (Autoload Singleton)

A dedicated **EventBus.gd** autoload acts as a global signal hub. Systems communicate through the bus — no direct node references between unrelated systems.

```gdscript
# EventBus.gd — global signal hub
signal boon_cast(boon_data, position)
signal npc_converted(npc)
signal shrine_built(shrine)
signal enemy_killed(enemy)
signal day_changed(day_number)
signal wave_started(wave_config)
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
| `Main.tscn` | Node2D | `main.gd` | Game loop, spawns NPCs, holds TileMap world |
| `NPC.tscn` | CharacterBody2D | `npc.gd` | StateChart: unaware / witness / follower |
| `Shrine.tscn` | StaticBody2D | `shrine.gd` | Timer → add energy to GodStats |
| `Boon.tscn` | Area2D | `boon.gd` | Spawned at cursor, detects NPCs, self-destructs |
| `Enemy.tscn` | CharacterBody2D | `enemy.gd` | Hunts nearest follower/shrine, reduces faith |
| `RivalAgent.tscn` | CharacterBody2D | `rival_agent.gd` | Stronger enemy — targets shrines directly |
| `HUD.tscn` | CanvasLayer | `hud.gd` | Energy bar, follower count, level badge, day counter |
| `GodStats.gd` | Autoload | — | All god variables + signals |
| `EventBus.gd` | Autoload | — | Global signal hub |
| `DayClock.gd` | Autoload | — | Day timer, emits day_changed signal |
| `BoonRegistry.gd` | Autoload | — | Holds all BoonData resources |
| `EnemySpawner.gd` | Autoload | — | Reads WAVE_TABLE, spawns enemies on day_changed |

---

## 8. Build Order

Do not skip ahead. Each phase builds on the last. Playable from Phase 4.

| Phase | Task | What You Are Building |
|-------|------|-----------------------|
| **1** | GodStats + EventBus + DayClock autoloads | Core singletons. ~60 lines total. Nothing else works without these. |
| **2** | TileMap world | Small grass/dirt map. Visual only. |
| **3** | NPC wandering | CharacterBody2D picks random point, walks to it. Movement only. |
| **4** | Click-to-cast boon | Mouse click spawns Boon.tscn. Area2D detects NPCs. Faith added. **PLAYABLE.** |
| **5** | NPC conversion | Faith threshold → change sprite, walk to shrine spot, spawn Shrine.tscn. |
| **6** | Shrine + energy | Shrine Timer fires every N seconds, calls GodStats.add_energy(). |
| **7** | HUD | CanvasLayer with Labels reacting to GodStats signals. Energy bar, follower count, level badge, day counter. |
| **8** | Level-up & unlock | Followers cross threshold → god_level++, emit level_up, unlock next boon via BoonRegistry. |
| **9** | DayClock + day counter | Real-time day cycle (3 min). HUD shows current day and time remaining. |
| **10** | Enemy spawner | EnemySpawner reads WAVE_TABLE on day_changed. Bandits hunt nearest follower. |
| **11** | Game over condition | followers == 0 → GodStats emits game_over(). Main.gd shows game over screen. |
| **12** | Win condition | Day 15 survived → win screen. |
| **13** | Rival god agents | RivalAgent.tscn spawns from Day 6. Targets shrines directly. |

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
