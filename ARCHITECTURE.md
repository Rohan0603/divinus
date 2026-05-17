# Architecture Documentation — DIVINUS

System design, data flow, and integration patterns.

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     DIVINUS SYSTEM                          │
├──────────────────────────┬──────────────────────────────────┤
│                          │                                  │
│   FRONTEND (Godot)       │       BACKEND (FastAPI)          │
│                          │                                  │
│  ┌──────────────────┐    │   ┌──────────────────────┐       │
│  │  Main Game Loop  │    │   │  Dialogue Engine     │       │
│  │  - NPCs          │◄──HTTP──│  - Mock Handler      │       │
│  │  - HUD           │    │   │  - LLM Handler       │       │
│  │  - Autoloads     │    │   │  - Request Router    │       │
│  └──────────────────┘    │   └──────────────────────┘       │
│         ▲                │             ▲                    │
│         │                │             │                    │
│   Signals (EventBus)     │        Ollama (Local LLM)        │
│         │                │             │                    │
│         └────────────────┴─────────────┘                    │
│              Global State Sync via Signals                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Frontend Architecture (Godot)

### Autoloads (Global Singletons)

**GodStats.gd**
```
Purpose: Centralized god power state
├── Variables:
│   ├── followers: int (0+)
│   ├── divine_power: float (0–max_divine_power)
│   ├── max_divine_power: float (100 at MVP)
│   ├── god_level: int (1-6)
│   ├── xp_thresholds: Array[int]
│   ├── shrines_built: int
│   ├── shrine_sites_pending: int
│   └── role_counts: Dictionary  # Builder/Gatherer/Farmer/Defender/Scholar
└── Signals:
    ├── followers_changed(new_count: int)
    ├── divine_power_changed(new_value: float)
    ├── level_up(new_level: int)
    └── game_over()
```

**EventBus.gd**
```
Purpose: Global signal hub for all systems
├── Signals:
│   ├── boon_cast(boon_data: Dictionary, position: Vector2)
│   ├── npc_converted(npc: Node)
│   ├── shrine_built(shrine: Node)
│   ├── enemy_killed(enemy: Node)
│   ├── day_changed(day_number: int)
│   ├── day_ending(day_number: int)       # 30s before day end — triggers raids
│   ├── wave_started(wave_config: Dictionary)
│   ├── shrine_unlocked()                  # every 5 followers
│   ├── shrine_site_placed(site_position: Vector2)
│   └── npc_role_assigned(npc: Node, role: String)
└── Pattern: Any system emits here, all listeners respond
```

**DayClock.gd**
```
Purpose: Time management and day progression
├── Variables:
│   └── current_day: int (1-15)
└── Behavior:
    ├── Two internal Timers (180s day, 150s warning)
    ├── 150s → day_ending.emit(current_day)   [triggers enemy raids]
    ├── 180s → current_day++, day_changed.emit(current_day)
    └── get_time_remaining() → _timer.time_left
```

### Scene Hierarchy

```
game/
├── Main.tscn (Node2D)
│   ├── Background (ColorRect — TileMap placeholder)
│   ├── TileMap (empty, future)
│   ├── UI (CanvasLayer)
│   │   └── HUD.tscn (CanvasLayer)
│   │       └── VBoxContainer
│   │           ├── DivinePowerLabel → watches GodStats.divine_power_changed
│   │           ├── FollowersLabel   → watches GodStats.followers_changed
│   │           ├── LevelLabel       → watches GodStats.level_up
│   │           └── DayLabel         → updated in _process via DayClock.get_time_remaining()
│   ├── NPC.tscn (CharacterBody2D) ×6 — spawned in _ready
│   │   ├── Polygon2D (shape + color encodes role)
│   │   └── match current_state → 8 states:
│   │       Unaware | Witness | HeadPreacher | Builder
│   │       Gatherer | Farmer | Defender | Scholar
│   ├── ShrineConstructionSite.tscn — spawned every 5 followers
│   │   └── 3 builders × 5s → shrine_completed.emit()
│   ├── Shrine.tscn (StaticBody2D) — spawned on shrine_completed
│   │   └── Timer 5s → GodStats.add_divine_power(10)
│   ├── Boon.tscn (Area2D) — spawned on left-click (costs 5 DP)
│   │   └── EventBus.boon_cast.emit({}, position)
│   └── Enemy.tscn (CharacterBody2D) — spawned by EnemySpawner on day_ending
│       └── hunts nearest follower → take_damage() on contact → start_exit()
```

### Signal Flow Diagram

```
Left-click → main.gd._input → spend 5 DP → Boon.tscn instantiated
  └─ boon.gd._ready → EventBus.boon_cast.emit({}, position)
       └─ NPC._on_boon_cast → witness_miracle() [if Unaware and within 200px]
            └─ current_state = "Witness" → faith accumulates 3/s

NPC faith >= 10 → _become_follower()
  ├─ GodStats.add_follower()
  │    ├─ followers_changed.emit()  → HUD updates label
  │    └─ shrine_unlocked.emit() [every 5 followers]
  │         └─ main.gd._on_shrine_unlocked → ShrineConstructionSite spawned
  └─ EventBus.npc_converted.emit(npc)
       └─ main.gd._on_npc_converted → first one → assign_head_preacher()

3 builders hold ShrineConstructionSite for 5s → shrine_completed.emit()
  └─ main.gd._on_shrine_completed → Shrine.tscn spawned, GodStats.on_shrine_built()

Shrine._ready → Timer 5s → GodStats.add_divine_power(10)
  └─ divine_power_changed.emit() → HUD updates DivinePowerLabel

DayClock 150s → day_ending → EnemySpawner → bandits spawn
DayClock 180s → day_changed → current_day++ → EnemySpawner exits stragglers

GodStats.followers == 0 → game_over.emit() → main.gd prints "Game Over!"
```

### NPC State Machine

The NPC uses a `current_state: String` variable dispatched in `_physics_process` via `match`. Each state maps to a dedicated `_update_<state>(delta)` method.

**States and behaviors:**

| State | Color | Behavior | Income |
|-------|-------|---------|--------|
| Unaware | Blue | Random wander | — |
| Witness | Yellow | Stationary; faith += 3/s; converts at 10 | — |
| HeadPreacher | Gold | Hunts Unaware NPCs, calls `witness_miracle()` at 32px | — |
| Builder | Orange | Walks to nearest ShrineConstructionSite | — |
| Gatherer | Teal | Wanders randomly | 3 DP / 5s |
| Farmer | Yellow-green | Orbits nearest shrine (40–80px) | 4 DP / 5s |
| Defender | Red | Chases nearest enemy; calls `start_exit()` at 40px | — |
| Scholar | Deep purple | Drifts to nearest shrine, stays within 48px | 2.5 DP / 5s |

```gdscript
func _physics_process(delta: float) -> void:
    match current_state:
        "Unaware":      _update_unaware(delta)
        "Witness":      _update_witness(delta)
        "HeadPreacher": _update_head_preacher(delta)
        "Builder":      _update_builder(delta)
        "Gatherer":     _update_gatherer(delta)
        "Farmer":       _update_farmer(delta)
        "Defender":     _update_defender(delta)
        "Scholar":      _update_scholar(delta)
    move_and_slide()
```

**Skill system:** Income roles earn 10 XP per income tick. At 100 XP → level up (max 5). Efficiency = `1.0 + skill_level / 5.0` (1.0× base → 2.0× max).

---

## Backend Architecture (FastAPI)

### Request/Response Flow

```
HTTP POST /npc/dialogue
  │
  ├─ Validate JSON (Pydantic model)
  │  └─ DialogueRequest: npc_id, state, boon_cast, day
  │
  ├─ Route based on USE_MOCK env variable
  │  │
  │  ├─ MOCK MODE:
  │  │  └─ mock_handler.get_mock_dialogue()
  │  │     └─ Return deterministic response (10 options rotate)
  │  │
  │  └─ LLM MODE:
  │     └─ llm_handler.get_llm_dialogue()
  │        └─ Call Ollama API (phi3:mini inference)
  │           └─ Parse + validate response
  │
  ├─ Validate response matches schema
  │  └─ DialogueResponse: dialogue, faith_bonus
  │
  └─ Return 200 OK with JSON body
```

### File Structure

```python
main.py
├── FastAPI app initialization
├── CORS middleware (allow all origins for dev)
├── Request/Response models (Pydantic)
│   ├── DialogueRequest (validation)
│   └── DialogueResponse (validation)
├── Endpoints:
│   ├── GET /health → {"status": "ok"}
│   └── POST /npc/dialogue → JSON response
└── Handler routing (if USE_MOCK then mock_handler else llm_handler)

mock_handler.py
├── 10 hardcoded dialogue templates
├── NPC personality + state variations
└── get_mock_dialogue() → {"dialogue": str, "faith_bonus": int}

llm_handler.py
├── Ollama API client
├── Prompt engineering
├── Response parsing & validation
├── Fallback to mock on error
└── get_llm_dialogue() → {"dialogue": str, "faith_bonus": int}

.env
├── USE_MOCK = true/false
└── OLLAMA_HOST = http://localhost:11434
```

### Configuration

**Environment Variables:**
```bash
USE_MOCK=true              # Toggle mock vs LLM
OLLAMA_HOST=http://localhost:11434  # Ollama service URL
DEBUG=false                # (Future) verbose logging
```

**Model Configuration:**
- **LLM:** Ollama phi3:mini (4B parameters)
- **Max tokens:** 50 (limits dialogue length)
- **Temperature:** 0.7 (balanced creativity)
- **Prompt:** System prompt contextualizes state/boon/day

### Error Handling Strategy

```
Request received
  │
  ├─ Pydantic validation fails
  │  └─ Return 422 Unprocessable Entity
  │
  ├─ Handler execution fails
  │  ├─ If LLM mode: fall back to mock
  │  ├─ Log error to console
  │  └─ Return mock response
  │
  ├─ Response validation fails
  │  ├─ Clamp faith_bonus to 5-20
  │  ├─ Log warning
  │  └─ Return corrected response
  │
  └─ Success
     └─ Return 200 OK + JSON
```

---

## Integration: Godot ↔ Backend

### Communication Protocol

**Godot → Backend (HTTP POST)**
```
URL: http://localhost:8000/npc/dialogue
Headers: Content-Type: application/json
Body: {
  "npc_id": 1,
  "state": "witness",
  "boon_cast": "heal",
  "day": 1
}
```

**Backend → Godot (HTTP 200)**
```
Headers: Content-Type: application/json
Body: {
  "dialogue": "My ailments vanish!",
  "faith_bonus": 19
}
```

### GDScript Implementation Pattern

```gdscript
# In npc.gd
func request_dialogue() -> void:
    var request = HTTPRequest.new()
    add_child(request)
    
    var body = JSON.stringify({
        "npc_id": npc_id,
        "state": current_state.name,
        "boon_cast": last_boon_cast,
        "day": DayClock.current_day
    })
    
    request.request_completed.connect(_on_dialogue_response)
    request.request(
        "http://localhost:8000/npc/dialogue",
        ["Content-Type: application/json"],
        HTTPClient.METHOD_POST,
        body
    )

func _on_dialogue_response(result, response_code, headers, body) -> void:
    if response_code == 200:
        var json = JSON.parse_string(body.get_string_from_utf8())
        dialogue = json["dialogue"]
        faith_bonus = json["faith_bonus"]
        apply_faith_gain()
    else:
        # Fallback to mock dialogue locally
        use_mock_dialogue()
```

### CORS Policy

**Development (current):**
```
allow_origins = ["*"]
allow_methods = ["*"]
allow_headers = ["*"]
allow_credentials = True
```

**Production (future):**
```
allow_origins = ["http://localhost:8080", "https://divinus.example.com"]
allow_methods = ["GET", "POST"]
allow_headers = ["Content-Type"]
```

---

## Data Flow: Complete Game Loop

### Turn 1: Player Casts Boon

```
1. Input Detection
   └─ Main.gd: _input(InputEvent)
      └─ If click detected: calculate_boon_effect()

2. Boon Resolution
   └─ Main.gd: calculate_boon_effect()
      ├─ Check GodStats.energy >= cost
      ├─ Reduce GodStats.energy
      ├─ Create Area2D at click position with radius
      └─ Query overlapping NPCs

3. NPC Notification
   └─ For each NPC in radius:
      ├─ npc.witness_miracle()
      ├─ Set state to "witness"
      └─ EventBus.boon_cast.emit()

4. Dialogue Request
   └─ npc.gd: request_dialogue()
      ├─ POST to http://localhost:8000/npc/dialogue
      └─ Wait for response (~2.2s LLM or <50ms mock)

5. Faith Application
   └─ On response:
      ├─ Add faith_bonus to npc.faith
      ├─ If faith >= threshold:
      │  ├─ Transition to "follower"
      │  ├─ GodStats.followers += 1
      │  └─ Shrine spawned
      └─ Display dialogue popup

6. HUD Update
   └─ EventBus.followers_changed.emit()
      └─ HUD.gd: update_ui()
         └─ Refresh follower count label
```

### Turn 2: Day Progression

```
1. Time Update
   └─ DayClock.gd: _process(delta)
      ├─ time_in_day += delta
      └─ If time_in_day >= DAY_LENGTH:

2. Day Changed Signal
   └─ EventBus.day_changed.emit(new_day)
      ├─ HUD updates day display
      ├─ Enemy spawner receives signal
      └─ New wave spawns (Days 1-15)

3. Enemy Wave Spawn
   └─ Enemies.gd: _on_day_changed(day)
      ├─ Calculate wave difficulty
      ├─ Spawn bandits/agents
      └─ Begin enemy attacks on followers

4. Win/Lose Check
   └─ If current_day > 15:
      ├─ EventBus.game_won.emit()
      └─ Load win screen
   └─ If GodStats.followers == 0:
      ├─ EventBus.game_over.emit()
      └─ Load lose screen
```

---

## Scalability Considerations

### Adding New Boons
**No code changes required:**
1. Create new `BoonData.tres` resource
2. Define: cost, radius, effect_type, cooldown
3. Add to `BoonRegistry` autoload
4. Backend automatically generates contextual dialogue

### Adding New NPC States
**Minimal code changes:**
1. Create new `class MyNewState extends BaseState`
2. Implement: enter(), update(delta), exit()
3. Add to NPC.states dictionary
4. Transition via npc.transition_to("new_state")

### Adding New Enemy Types
**Isolated changes:**
1. Create new `Enemy.tscn` scene
2. Implement movement + collision logic
3. Add spawn logic to enemy wave system
4. No changes to core game loop

### Backend Scalability
- **Mock mode:** Single-threaded, instant responses
- **LLM mode:** Sequential inference (one request at a time)
  - Can queue requests if needed
  - Switch to concurrent requests with asyncio (future)
- **Database:** Currently stateless (future: PostgreSQL for persistence)

---

## Performance Metrics

| Component | Metric | Target | Current |
|-----------|--------|--------|---------|
| Backend (mock) | Response time | <100ms | <50ms ✅ |
| Backend (LLM) | Response time | <5s | 2.2s ✅ |
| Game FPS | Target | 60 FPS | (untested) |
| NPC update | Per-frame overhead | <5ms | (untested) |
| Memory (Godot) | Target | <500MB | (untested) |
| Memory (Backend) | Target | <200MB (mock) | (untested) |
| Memory (LLM) | Target | <2GB | ~2GB ✅ |

---

## Future Improvements

### Short-term (Post-MVP)
- Async HTTP requests in Godot (prevent frame stutter)
- Response caching by NPC/state combination
- Batch dialogue requests (multiple NPCs)
- Database persistence (followers, shrines, etc.)

### Medium-term
- Rival god AI system (competing for followers)
- More sophisticated NPC personalities
- Procedural dialogue generation variants
- Multi-language support

### Long-term
- Multiplayer (shared world, competing gods)
- Mobile platform support
- Advanced LLM models (faster inference)
- Cloud backend deployment

---

**Last Updated:** 2026-05-17  
**Architecture Version:** 1.1
