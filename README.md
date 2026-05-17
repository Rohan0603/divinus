# 🎮 DIVINUS — A Top-Down 2D God Game

**Godot 4.6 · GDScript · Python FastAPI Backend · Ollama LLM Integration**

A beginner-scope god game where you guide NPCs, cast divine boons, and build a civilization while defending against increasingly difficult enemy waves. **Survive 15 in-game days to win.**

---

## 📋 Project Structure

```
divinus/
├── game/                          # Godot 4.6 frontend
│   ├── project.godot               # Project config + autoload registration
│   ├── CLAUDE.md                   # Game dev guide
│   ├── GODOT_SETUP.md              # Editor extensions & tools
│   ├── autoloads/                  # Global singletons
│   │   ├── GodStats.gd             # God variables + signals
│   │   ├── EventBus.gd             # Global signal hub
│   │   └── DayClock.gd             # Day/night cycle (180s = 1 day)
│   └── scenes/                     # Scenes + co-located scripts
│       ├── Main.tscn + main.gd     # World root + game loop
│       ├── NPC.tscn + NPC.gd       # 8-state NPC (roles + skill system)
│       ├── HUD.tscn + HUD.gd       # UI (divine power, followers, level, day)
│       ├── Shrine.tscn + Shrine.gd
│       ├── ShrineConstructionSite.tscn + ShrineConstructionSite.gd
│       ├── Boon.tscn + boon.gd
│       └── Enemy.tscn + enemy.gd
│
├── backend/                        # FastAPI NPC dialogue engine
│   ├── main.py                     # FastAPI app + endpoints
│   ├── mock_handler.py             # 10 deterministic NPC responses
│   ├── llm_handler.py              # Ollama phi3:mini integration
│   ├── requirements.txt            # Dependencies
│   ├── .env                        # Config (USE_MOCK, OLLAMA_HOST)
│   ├── .env.example                # Config template
│   ├── README.md                   # Backend setup & testing
│   └── server.log                  # Server logs
│
├── divinus_gdd.md                  # Full Game Design Document
├── README.md                       # This file
└── .gitignore

```

---

## 🚀 Quick Start

### Backend (Dialogue Engine)

**Prerequisites:**
- Python 3.10+
- Ollama (optional; mock mode works without it)

**Setup:**
```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
```

**Run (Mock Mode — no GPU needed):**
```bash
USE_MOCK=true python main.py
```

**Run (Real Mode — requires Ollama):**
```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Set LLM mode in backend/.env
# USE_MOCK=false

# Start backend
python main.py
```

**Test:**
```bash
curl -X POST http://localhost:8000/npc/dialogue \
  -H "Content-Type: application/json" \
  -d '{"npc_id": 1, "state": "witness", "boon_cast": "heal", "day": 1}'
```

**Response Time:** ~2.2 seconds (Ollama + phi3:mini)

---

### Godot Frontend

**Prerequisites:**
- Godot 4.6.2+ ([Download](https://godotengine.org))
- Windows PowerShell or Bash

**Launch:**
```powershell
# If Godot 4.6.2 is in PATH:
godot --path "C:\project!!\divinus\game"

# Or open game/project.godot directly in Godot Editor
```

**Test in-game:**
Open **Debugger Console** in Godot:
```gdscript
# Trigger NPC conversion
get_tree().get_first_child_in_group("npc").witness_miracle()

# Check follower count
print(GodStats.followers)
```

---

## 📊 Architecture Overview

### System Components

| Component | Role | Technology |
|-----------|------|-----------|
| **Frontend (Game)** | Player controls, NPC visuals, HUD | Godot 4.6, GDScript |
| **Backend (API)** | NPC dialogue generation on demand | FastAPI, Python |
| **LLM** | AI dialogue responses | Ollama phi3:mini (local) |
| **Communication** | Game ↔ Backend requests | HTTP REST + CORS |
| **State Management** | Global game state | Autoloads (singletons) |
| **Events** | System communication | GDScript signals |

### Data Flow

```
1. Player clicks to cast boon
2. Boon effect calculated (radius, NPCs affected)
3. NPC marks as "witness"
4. Backend: /npc/dialogue POST request
   → Mock response OR LLM generates dialogue
5. Response: { dialogue: string, faith_bonus: 5-20 }
6. NPC gains faith, converts if threshold crossed
7. HUD updates via GodStats signals
```

---

## ⚙️ Key Systems

### NPCs (State Machine)
Each NPC cycles through states/roles:
- **Unaware** (blue) — Wander randomly
- **Witness** (yellow) — Stationary; faith accumulates 3/s; converts at 10
- **HeadPreacher** (gold) — Hunts Unaware NPCs, triggers `witness_miracle()`
- **Builder** (orange) — Walks to ShrineConstructionSite
- **Gatherer** (teal) — Wanders randomly; 3 DP / 5s
- **Farmer** (yellow-green) — Orbits nearest shrine; 4 DP / 5s
- **Defender** (red) — Chases enemies; pushes them off the map
- **Scholar** (deep purple) — Drifts near shrines; 2.5 DP / 5s

### Boons (Divine Abilities)
- **Heal** — Restore NPC health (Level 1)
- **Bountiful Harvest** — Grow crops, faster faith (Level 2)
- **Divine Shield** — Protect followers (Level 3)
- **Smite** — Destroy enemies (Level 4)
- **Divine Beacon** — Passive conversion aura (Level 5)
- **World Reshape** — Alter terrain (Level 6)

### God Progression
- **Followers = XP** — Convert NPCs to increase level
- **Levels unlock boons** — New abilities at each tier
- **Skill system** — Income roles level up to 2× output over time

### Day/Night Cycle
- **1 in-game day = 180 real seconds**
- **Days 1–5:** Bandit waves only
- **Days 6–10:** Bandits + rival god scouts
- **Days 11–15:** Full rival god assault

### Win/Fail
- **Win:** Survive day 15
- **Fail:** Followers drop to 0

---

## 🧪 Testing Status

### Backend Tests ✅
| Test | Result | Time |
|------|--------|------|
| Health check | ✅ Pass | instant |
| Mock dialogue (5 requests) | ✅ Pass | 0.5s avg |
| LLM dialogue (Ollama) | ✅ Pass | 2.2s avg |
| Dialogue validation | ✅ Pass | — |
| CORS headers | ✅ Pass | — |

### Frontend Status
- ✅ Autoloads (GodStats, EventBus, DayClock, EnemySpawner)
- ✅ NPC spawning + wandering
- ✅ Boon casting (left-click, costs 5 DP)
- ✅ NPC conversion (8-state role system + skill progression)
- ✅ Head Preacher auto-conversion
- ✅ Shrine construction pipeline (3 builders × 5s)
- ✅ Shrine divine power generation (10 DP / 5s)
- ✅ HUD (divine power, followers, level, day/time)
- ✅ Enemy raids (WAVE_TABLE, day_ending trigger)
- ✅ Game over condition (followers == 0)
- ⬜ TileMap world (ColorRect placeholder)
- ⬜ Win condition (survive day 15)

---

## 📚 Documentation

| File | Purpose |
|------|---------|
| **divinus_gdd.md** | Full design document (15 pages) |
| **game/CLAUDE.md** | Frontend dev guide + architecture |
| **game/GODOT_SETUP.md** | Editor extensions & workflow |
| **backend/README.md** | Backend setup + API docs |
| **README.md** | This file — project overview |

---

## 🛠️ Development Workflow

### Adding a Boon
1. Create new `BoonData.tres` resource with cost/radius/cooldown
2. Add to `BoonRegistry` autoload
3. Backend auto-generates dialogue for any boon via `/npc/dialogue` endpoint

### Adding an Enemy Type
1. Create `Enemy.tscn` scene with movement + collision
2. Add spawn logic to `EventBus.wave_started` listener
3. Configure wave table in `DayClock`

### Connecting to Backend
Backend is **optional** for MVP. Without it:
- Mock responses are shown (deterministic, testing-friendly)
- 10 hardcoded dialogue options rotate

To use real LLM dialogue:
1. Install Ollama + pull `phi3:mini`
2. Set `USE_MOCK=false` in backend/.env
3. Godot makes HTTP POST to `http://localhost:8000/npc/dialogue`

---

## 🎯 Build Phases (Recommended Order)

**Phase 1:** ✅ Autoloads (GodStats, EventBus, DayClock, EnemySpawner)  
**Phase 2:** ⬜ TileMap world (ColorRect placeholder)  
**Phase 3:** ✅ NPC wandering  
**Phase 4:** ✅ Click-to-cast boon + radius detection  
**Phase 5:** ✅ NPC conversion + 8-state role system + skill progression  
**Phase 6:** ✅ Shrine construction pipeline (3 builders × 5s)  
**Phase 7:** ✅ Shrine divine power generation (10 DP / 5s)  
**Phase 8:** ✅ HUD (divine power, followers, level, day/time)  
**Phase 9:** ✅ Head Preacher auto-conversion  
**Phase 10:** ✅ Enemy raids (WAVE_TABLE, day_ending trigger)  
**Phase 11:** ✅ Game over condition (followers == 0)  
**Phase 12:** ⬜ Win condition (survive day 15)  

---

## 📖 References

**Design:**
- [Full GDD](divinus_gdd.md)
- Inspiration: Black & White (2001), Reus (2013), Populous (1989)

**Godot:**
- [Godot 4.6 Docs](https://docs.godotengine.org)
- GDQuest (free 2D tutorials)
- KidsCanCode (beginner series)

**Backend:**
- [FastAPI Docs](https://fastapi.tiangolo.com)
- [Ollama Docs](https://ollama.ai)
- [phi3:mini Model Card](https://huggingface.co/microsoft/Phi-3-mini-4k-instruct)

---

## 👥 Team

**Developer:** Gokul Kushalappa  
**Project:** Divinus (2026)

---

**Status:** In Development · MVP Phase 11/12 (TileMap + win screen remaining)  
**Last Updated:** 2026-05-17
