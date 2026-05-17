# Development Guidelines — DIVINUS

Best practices, coding standards, and workflow for frontend and backend development.

---

## Quick Links

- **Game Design:** [divinus_gdd.md](divinus_gdd.md)
- **Frontend Guide:** [game/CLAUDE.md](game/CLAUDE.md)
- **Backend Setup:** [backend/README.md](backend/README.md)
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **Testing:** [TESTING.md](TESTING.md)

---

## Development Environment Setup

### Prerequisites

**All developers:**
- Git (for version control)
- Windows 11 or macOS/Linux
- Text editor (VS Code recommended)

**Frontend developers:**
- Godot 4.6.2+ ([download](https://godotengine.org))
- (Optional) VS Code + GDScript extension

**Backend developers:**
- Python 3.10+ ([download](https://www.python.org))
- Ollama 0.24.0+ ([download](https://ollama.ai)) — optional
- VS Code or PyCharm

### Initial Setup

```bash
# 1. Clone repository
git clone <repo-url>
cd divinus

# 2. Frontend setup (Godot)
# → Open Godot Editor → Open project at game/project.godot

# 3. Backend setup (Python)
cd backend
pip install -r requirements.txt
cp .env.example .env

# 4. (Optional) Ollama setup
ollama pull phi3:mini
```

---

## Frontend Development (Godot/GDScript)

### File Structure

```
game/
├── autoloads/              # Global singletons
│   ├── GodStats.gd         # followers, divine_power, shrine tracking, role_counts
│   ├── EventBus.gd         # all signals
│   ├── DayClock.gd         # 180s day timer + 150s raid warning
│   └── EnemySpawner.gd     # WAVE_TABLE, spawns bandits on day_ending
├── scenes/                 # Scenes and their co-located scripts
│   ├── Main.tscn + main.gd
│   ├── NPC.tscn + NPC.gd
│   ├── HUD.tscn + HUD.gd
│   ├── Shrine.tscn + Shrine.gd
│   ├── ShrineConstructionSite.tscn + ShrineConstructionSite.gd
│   ├── Boon.tscn + boon.gd
│   └── Enemy.tscn + enemy.gd
└── resources/              # Data resources (future)
```

### Coding Standards

#### 1. Signals Over Polling
**Bad:**
```gdscript
# main.gd
if GodStats.followers > 10:
    show_level_up_popup()
```

**Good:**
```gdscript
# In ready()
GodStats.level_up.connect(_on_level_up)

func _on_level_up(new_level: int):
    show_level_up_popup()
```

#### 2. Use Inner Classes for States
**Bad:**
```gdscript
# npc.gd with big if/else state logic
func _process(delta):
    if state == "unaware":
        wander()
    elif state == "witness":
        freeze()
    elif state == "follower":
        walk_to_shrine()
```

**Good:**
```gdscript
# npc.gd with inner classes
class Unaware extends BaseState:
    func enter(): pass
    func update(delta): pass
    func exit(): pass

func transition_to(state_name: String):
    current_state.exit()
    current_state = states[state_name]
    current_state.enter()
```

#### 3. No Hardcoded Values
**Bad:**
```gdscript
# npc.gd
speed = 150  # Hardcoded
```

**Good:**
```gdscript
# At top of npc.gd
const SPEED = 150
const WANDER_RADIUS = 200

# Or use scene properties (exposed in editor)
@export var speed: float = 150.0
```

#### 4. Flat Scene Hierarchy
**Bad:**
```
Main
└─ World
   └─ Enemies
      └─ Bandit.tscn  ← Too deep
```

**Good:**
```
Main
├─ Bandit.tscn (instance)
├─ NPC.tscn (instance)
└─ HUD.tscn (instance)
```

#### 5. Type Hints
```gdscript
# Always use type hints
func cast_boon(position: Vector2, boon: String) -> bool:
    return true

func get_npcs_in_radius(position: Vector2, radius: float) -> Array[Node]:
    return []
```

#### 6. Grouping for Queries
```gdscript
# In _ready()
add_to_group("npc")
add_to_group("follower")

# In main.gd
var all_npcs = get_tree().get_nodes_in_group("npc")
var followers = get_tree().get_nodes_in_group("follower")
```

### Phase Structure

**Phases 1, 3–13 (Complete):**
- Autoloads: GodStats, EventBus, DayClock, EnemySpawner
- NPC wandering, boon casting, conversion, 8-state role system + skill progression
- Shrine construction pipeline (sites → builders → built shrines)
- HUD (divine power, followers, level, day/time)
- Head Preacher auto-conversion
- Enemy raids (WAVE_TABLE, day_ending trigger)
- Game over condition (followers == 0)

**Phase 2 (Pending):**
- TileMap world (currently a ColorRect placeholder)

**Phases 14–15 (Pending):**
- Win condition (survive day 15)
- Rival god agents (post-MVP)

### Code Review Checklist

Before committing:
- [ ] Signals used instead of polling
- [ ] Type hints on all functions
- [ ] No hardcoded values (use constants)
- [ ] Comments only for **why**, not **what**
- [ ] Flat scene hierarchy (max 1 level nesting)
- [ ] No direct node references between systems
- [ ] Tested in Godot (at least 10 seconds playtime)
- [ ] No console errors/warnings

---

## Backend Development (FastAPI/Python)

### File Structure

```
backend/
├── main.py                 # FastAPI app + endpoints
├── mock_handler.py         # Deterministic dialogue
├── llm_handler.py          # Ollama integration
├── requirements.txt        # Dependencies
├── .env                    # Local config (not in git)
├── .env.example            # Config template
├── README.md               # Setup instructions
└── server.log              # Server logs
```

### Coding Standards

#### 1. Type Hints (PEP 484)
```python
def get_dialogue(
    npc_id: int,
    state: str,
    boon_cast: str,
    day: int
) -> dict[str, Any]:
    return {"dialogue": "...", "faith_bonus": 15}
```

#### 2. Docstrings
```python
def get_mock_dialogue(
    npc_id: int,
    state: str,
    boon_cast: str,
    day: int
) -> dict[str, Any]:
    """
    Generate deterministic NPC dialogue response.
    
    Args:
        npc_id: Unique NPC identifier (1+)
        state: NPC emotional state (witness, grateful, afraid)
        boon_cast: Divine boon cast (heal, bless, protect)
        day: Current game day (1-15)
    
    Returns:
        Dictionary with 'dialogue' (str) and 'faith_bonus' (int, 5-20)
    """
```

#### 3. Error Handling
```python
try:
    result = call_ollama_api(prompt)
    response = validate_response(result)
except OllamaConnectionError as e:
    logger.warning(f"Ollama failed: {e}, falling back to mock")
    return get_mock_dialogue(npc_id, state, boon_cast, day)
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    raise
```

#### 4. Configuration Management
```python
# .env file
USE_MOCK=true
OLLAMA_HOST=http://localhost:11434
LOG_LEVEL=INFO

# main.py
import os
from dotenv import load_dotenv

load_dotenv()
USE_MOCK = os.getenv("USE_MOCK", "true").lower() == "true"
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
```

#### 5. Logging
```python
import logging

logger = logging.getLogger(__name__)
logger.info("Server started in mock mode")
logger.warning("Ollama connection failed, using mock")
logger.error("Invalid response format from LLM")
```

### Testing Checklist

Before committing:
- [ ] `pip install -r requirements.txt` succeeds
- [ ] `USE_MOCK=true python main.py` runs without error
- [ ] Health endpoint: `curl http://localhost:8000/health` → 200
- [ ] Dialogue endpoint: POST with valid JSON → 200 + valid response
- [ ] faith_bonus always 5-20
- [ ] Invalid JSON → 422 (validation error)
- [ ] Response time <5s (LLM mode)
- [ ] No unhandled exceptions in logs
- [ ] CORS headers present in response

### API Response Contract

**Always return this structure:**
```json
{
  "dialogue": "string (max 20 words)",
  "faith_bonus": integer (5-20)
}
```

**Never return:**
```json
// Bad: extra fields
{
  "dialogue": "...",
  "faith_bonus": 15,
  "debug_info": "..."
}

// Bad: missing fields
{
  "dialogue": "..."
}

// Bad: invalid values
{
  "dialogue": "...",
  "faith_bonus": 25  // > 20
}
```

---

## Git Workflow

### Branch Naming
```
feature/npc-state-machine
feature/backend-llm-integration
bugfix/dialogue-validation
docs/update-readme
```

### Commit Messages

**Format:**
```
[component] Summary (under 50 chars)

Detailed explanation (under 72 chars per line).
- Bullet points for multiple changes
- Reference issues if applicable

Fixes: #123
```

**Example:**
```
[frontend] Implement NPC state machine

- Add BaseState class with enter/update/exit
- Implement Unaware, Witness, Follower states
- Add state transitions on faith threshold

Fixes: #15
```

### Pull Request Template
```markdown
## Summary
Brief description of changes.

## Related Issues
Fixes #123

## Changes
- Change 1
- Change 2

## Testing
- [ ] Tested in Godot (frontend)
- [ ] Tested with mock backend
- [ ] Tested with LLM backend (if applicable)
- [ ] No console errors
- [ ] Performance acceptable

## Checklist
- [ ] Code follows style guide
- [ ] Self-reviewed my code
- [ ] Added necessary comments
- [ ] Tests added/updated
```

---

## Debugging Techniques

### Godot Debugging

**Console Output:**
```gdscript
print("NPC position: ", position)
print("Followers: ", GodStats.followers)
print("State: ", current_state.__class__)
```

**Debugger Breakpoints:**
1. Click line number in editor
2. Run game
3. Execution pauses at breakpoint
4. Step through with F10/F11

**Remote Debugger:**
1. In Godot: **Debug → Attach to Process**
2. Select running Godot instance
3. Set breakpoints in VS Code

### Backend Debugging

**Log Levels:**
```python
logging.basicConfig(level=logging.DEBUG)  # Most verbose
logging.basicConfig(level=logging.INFO)   # Default
logging.basicConfig(level=logging.WARNING) # Less verbose
```

**Request Inspection:**
```bash
# See full request + response
curl -v -X POST http://localhost:8000/npc/dialogue \
  -H "Content-Type: application/json" \
  -d '{"npc_id": 1, "state": "witness", "boon_cast": "heal", "day": 1}'
```

**Ollama Debugging:**
```bash
# Check Ollama is running
curl http://localhost:11434/api/tags

# Check model inference
ollama run phi3:mini "Say hello"
```

---

## Performance Optimization

### Frontend Optimization

**Avoid:**
- ❌ Polling state every frame
- ❌ Creating nodes in `_process()`
- ❌ Deep scene hierarchies
- ❌ Querying all nodes per frame

**Prefer:**
- ✅ Using signals (event-driven)
- ✅ Object pooling for frequently created nodes
- ✅ Flat hierarchies
- ✅ Groups + `get_nodes_in_group()`

### Backend Optimization

**Caching Opportunities:**
```python
# Cache dialogue for repeated requests
@functools.lru_cache(maxsize=100)
def get_cached_dialogue(npc_id: int, state: str, boon: str, day: int):
    return get_llm_dialogue(npc_id, state, boon, day)
```

**Batch Processing (Future):**
```python
# For multiple NPCs, batch requests
def batch_dialogue(requests: List[DialogueRequest]) -> List[DialogueResponse]:
    # Send multiple requests in parallel
    pass
```

---

## Dependencies Management

### Frontend
- Godot 4.6.2+ (built-in)
- No external packages needed for MVP

### Backend
```txt
fastapi>=0.100.0       # Web framework
uvicorn>=0.24.0        # ASGI server
python-dotenv>=1.0.0   # Config from .env
ollama>=0.1.0          # Ollama client
pydantic>=2.0          # Data validation
```

**Update dependencies:**
```bash
pip install --upgrade -r requirements.txt
```

**Freeze dependencies:**
```bash
pip freeze > requirements.txt
```

---

## Deployment (Future)

### Backend Deployment Checklist
- [ ] Switch to production database (PostgreSQL)
- [ ] Restrict CORS to specific origins
- [ ] Enable HTTPS/SSL
- [ ] Set up rate limiting
- [ ] Enable request logging
- [ ] Monitor response times
- [ ] Set up alerts for errors
- [ ] Backup strategy for dialogue cache

### Frontend Deployment Checklist
- [ ] Build for Web (future, if needed)
- [ ] Test on mobile (future)
- [ ] Performance profiling
- [ ] Mobile-optimized UI
- [ ] Offline support (if applicable)

---

## Resources & References

### Godot
- [Official Docs](https://docs.godotengine.org)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/style_guide/gdscript.html)
- GDQuest YouTube channel (free tutorials)
- KidsCanCode YouTube channel (beginner-friendly)

### Python
- [PEP 8 Style Guide](https://pep8.org)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Python Type Hints](https://docs.python.org/3/library/typing.html)

### Other
- [REST API Best Practices](https://restfulapi.net)
- [Git Workflow](https://git-scm.com/docs)
- [Markdown Syntax](https://commonmark.org)

---

## Getting Help

### Common Issues

**Godot won't launch:**
```bash
godot --version
# Should show 4.6.2 or higher

# If not in PATH, download from godotengine.org
```

**Backend connection fails:**
```bash
# Check if backend is running
curl http://localhost:8000/health

# Check firewall/port 8000
lsof -i :8000
```

**Ollama not responding:**
```bash
# Verify Ollama is running
curl http://localhost:11434/api/tags

# Restart Ollama
killall ollama
ollama serve
```

### Where to Ask Questions

- **Architecture questions:** Check ARCHITECTURE.md
- **API questions:** Check backend/README.md
- **Godot questions:** Check game/CLAUDE.md
- **Bugs:** Create GitHub issue with details
- **Design decisions:** Check divinus_gdd.md

---

**Last Updated:** 2026-05-17  
**Maintainer:** Gokul Kushalappa
