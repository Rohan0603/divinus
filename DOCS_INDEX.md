# Documentation Index — DIVINUS

Complete guide to all documentation files in the project.

---

## 📚 Main Documentation Files

### 1. **README.md** (START HERE)
**Purpose:** Project overview and quick start  
**Audience:** Everyone (developers, designers, stakeholders)  
**Contains:**
- Project structure overview
- Quick start instructions (backend + frontend)
- Architecture overview
- Testing status
- Build phases
- Key references

**When to read:**
- First time onboarding
- Quick reference for setup
- Status check

---

### 2. **divinus_gdd.md** (Game Design)
**Purpose:** Complete game design document  
**Audience:** Game designers, all developers  
**Contains:**
- Detailed core gameplay loop
- Win/fail conditions
- All game systems (NPCs, boons, progression, enemies)
- Day/night cycle specifications
- Full boon list with mechanics
- Enemy wave configuration
- Dialogue system design

**When to read:**
- Understanding game mechanics
- Adding new features
- Design questions
- Content decisions

---

### 3. **ARCHITECTURE.md** (System Design)
**Purpose:** Technical architecture and data flow  
**Audience:** Developers  
**Contains:**
- System architecture diagram
- Frontend architecture (Godot)
- Backend architecture (FastAPI)
- Complete signal flow diagram
- Integration: Godot ↔ Backend
- State machine pattern
- Performance metrics
- Future improvements

**When to read:**
- Understanding system design
- Making architectural decisions
- Integrating new systems
- Performance optimization

---

### 4. **TESTING.md** (Testing Guide)
**Purpose:** Complete testing procedures  
**Audience:** QA, developers  
**Contains:**
- Backend testing (mock + LLM mode)
- Performance benchmarks
- Frontend manual tests
- Integration tests
- Continuous integration checklist
- Troubleshooting guide
- Test results summary

**When to read:**
- Before committing code
- Testing changes
- Verifying functionality
- Performance regression checking

---

### 5. **DEVELOPMENT.md** (Development Guide)
**Purpose:** Developer guidelines and best practices  
**Audience:** All developers  
**Contains:**
- Environment setup
- Frontend coding standards (GDScript)
- Backend coding standards (Python)
- Phase structure
- Code review checklist
- Git workflow
- Debugging techniques
- Performance optimization
- Dependency management

**When to read:**
- Starting development
- Code review process
- Debugging issues
- Onboarding new developers

---

## 📂 Frontend Documentation

### **game/CLAUDE.md** (Frontend Dev Guide)
**Purpose:** Godot-specific development guide  
**Location:** `game/CLAUDE.md`  
**Contains:**
- Quick Godot setup
- Architecture overview (autoloads, scenes)
- State machine pattern for NPCs
- Build order/phases
- Core systems (win/fail, progression, boons, day cycle)
- Development guidelines (signals, hierarchy, state machines)
- File structure
- Testing the setup
- Backend integration for dialogue
- Post-MVP ideas

**When to read:**
- Frontend development
- Understanding Godot architecture
- Implementing game features

---

### **game/GODOT_SETUP.md** (Editor Setup)
**Purpose:** Godot editor extensions and tools  
**Location:** `game/GODOT_SETUP.md`  
**Contains:**
- Recommended Godot addons (Debug Console, Formatter, etc.)
- VS Code extensions for GDScript
- Built-in Godot tools
- Development workflow
- Performance optimization tools
- Setup checklist

**When to read:**
- Setting up Godot editor
- Improving development experience
- Installing editor extensions

---

## 🔧 Backend Documentation

### **backend/README.md** (Backend Setup & API)
**Purpose:** Backend setup and API documentation  
**Location:** `backend/README.md`  
**Contains:**
- Quick start (mock + real mode)
- API endpoints (/health, /npc/dialogue)
- Example requests/responses
- File structure
- Configuration (.env)
- Ollama setup guide
- Response format
- Error handling
- CORS configuration
- Logging
- Next steps

**When to read:**
- Backend development
- Setting up backend server
- Testing API endpoints
- Backend deployment

---

## 🔍 Lookup Guide

### "How do I...?"

| Question | Document | Section |
|----------|----------|---------|
| Get started? | README.md | Quick Start |
| Set up backend? | backend/README.md | Quick Start |
| Set up Godot? | game/CLAUDE.md | Quick Setup |
| Understand the architecture? | ARCHITECTURE.md | System Overview |
| Add a new feature? | divinus_gdd.md + DEVELOPMENT.md | Design + Guidelines |
| Add a new boon? | game/CLAUDE.md | Boons section |
| Add a new enemy? | game/CLAUDE.md | Scalability |
| Test my changes? | TESTING.md | Full guide |
| Debug frontend? | DEVELOPMENT.md | Godot Debugging |
| Debug backend? | DEVELOPMENT.md | Backend Debugging |
| Integrate backend? | game/CLAUDE.md | Backend Integration |
| Optimize performance? | DEVELOPMENT.md | Performance Optimization |
| Deploy backend? | DEVELOPMENT.md | Deployment |
| Understand signals? | ARCHITECTURE.md | Signal Flow |
| Understand NPC states? | game/CLAUDE.md | State Machine Pattern |
| Understand day cycle? | divinus_gdd.md | Day & Night Cycle |

---

## 📊 Documentation Structure

```
divinus/
│
├── README.md ........................... Project overview (START HERE)
├── divinus_gdd.md ...................... Game Design Document
├── ARCHITECTURE.md ..................... System design & data flow
├── TESTING.md .......................... Testing procedures
├── DEVELOPMENT.md ...................... Developer guidelines
├── DOCS_INDEX.md ....................... This file
│
├── game/
│   ├── CLAUDE.md ....................... Godot dev guide
│   ├── GODOT_SETUP.md .................. Editor setup
│   ├── project.godot ................... Project config
│   ├── autoloads/ ...................... Global singletons
│   ├── scenes/ ......................... Game scenes
│   └── scripts/ ........................ Scene logic
│
└── backend/
    ├── README.md ....................... Backend setup
    ├── main.py ......................... FastAPI app
    ├── mock_handler.py ................. Deterministic responses
    ├── llm_handler.py .................. Ollama integration
    ├── requirements.txt ................ Dependencies
    └── .env ............................ Configuration
```

---

## 🎯 Reading Paths by Role

### **Frontend Developer**
1. README.md (overview)
2. game/CLAUDE.md (setup + architecture)
3. game/GODOT_SETUP.md (tools)
4. divinus_gdd.md (game mechanics)
5. ARCHITECTURE.md (signal flow)
6. DEVELOPMENT.md (coding standards)

### **Backend Developer**
1. README.md (overview)
2. backend/README.md (setup)
3. ARCHITECTURE.md (backend design)
4. DEVELOPMENT.md (Python standards)
5. TESTING.md (backend tests)

### **Full-Stack Developer**
1. README.md
2. ARCHITECTURE.md
3. game/CLAUDE.md
4. backend/README.md
5. DEVELOPMENT.md
6. TESTING.md
7. divinus_gdd.md

### **Game Designer**
1. README.md
2. divinus_gdd.md (detailed mechanics)
3. game/CLAUDE.md (implementation overview)

### **QA/Tester**
1. README.md
2. TESTING.md (complete guide)
3. ARCHITECTURE.md (understanding flow)
4. backend/README.md (API testing)

### **Project Manager**
1. README.md
2. divinus_gdd.md
3. DEVELOPMENT.md (process)

---

## 📈 Documentation Status

| Document | Status | Last Updated | Completeness |
|----------|--------|--------------|-------------|
| README.md | ✅ Updated | 2026-05-16 | 100% |
| divinus_gdd.md | ✅ Complete | 2026-05-16 | 100% |
| ARCHITECTURE.md | ✅ New | 2026-05-16 | 100% |
| TESTING.md | ✅ New | 2026-05-16 | 100% |
| DEVELOPMENT.md | ✅ New | 2026-05-16 | 100% |
| DOCS_INDEX.md | ✅ New | 2026-05-16 | 100% |
| game/CLAUDE.md | ✅ Updated | 2026-05-16 | 95% |
| game/GODOT_SETUP.md | ✅ Complete | 2026-05-16 | 100% |
| backend/README.md | ✅ Complete | 2026-05-16 | 100% |

---

## 🔗 Quick Links

**Setup:**
- [Backend Setup](backend/README.md#-quick-start)
- [Frontend Setup](game/CLAUDE.md#quick-setup)
- [Editor Extensions](game/GODOT_SETUP.md)

**Development:**
- [GDScript Standards](DEVELOPMENT.md#frontend-development-godotgdscript)
- [Python Standards](DEVELOPMENT.md#backend-development-fastapipython)
- [Git Workflow](DEVELOPMENT.md#git-workflow)

**Testing:**
- [Backend Tests](TESTING.md#backend-testing)
- [Frontend Tests](TESTING.md#frontend-testing-godot)
- [Performance Benchmarks](TESTING.md#performance-benchmarks)

**Design:**
- [Core Systems](divinus_gdd.md#4-key-systems-mvp)
- [NPC State Machine](game/CLAUDE.md#state-machine-pattern-npc)
- [Signal Architecture](ARCHITECTURE.md#signal-flow-diagram)

---

## 📝 How to Update Docs

### When to Update
- After implementing a feature
- After fixing a bug that wasn't obvious
- After architectural changes
- After testing reveals new patterns
- Quarterly review

### What to Update
1. **README.md:** Status section, build phases
2. **divinus_gdd.md:** New mechanics, balance changes
3. **game/CLAUDE.md:** New systems, architectural changes
4. **ARCHITECTURE.md:** Data flow changes, new integrations
5. **DEVELOPMENT.md:** New coding standards, debugging techniques
6. **TESTING.md:** New test cases, performance changes

### How to Update
1. Edit the relevant file(s)
2. Keep format consistent
3. Update last-modified date
4. Update this index if structure changes
5. Include in commit message: "docs: update [filename]"

---

## ❓ FAQ

**Q: Where do I start?**  
A: Read README.md, then your role-specific path above.

**Q: I'm implementing a feature. What do I read?**  
A: DEVELOPMENT.md (guidelines) + divinus_gdd.md (design) + relevant frontend/backend docs.

**Q: I'm debugging an issue. Where do I look?**  
A: DEVELOPMENT.md (debugging section) + ARCHITECTURE.md (data flow).

**Q: The docs conflict. Which is authoritative?**  
A: divinus_gdd.md (design) > ARCHITECTURE.md (technical) > CLAUDE.md (implementation).

**Q: How do I find API documentation?**  
A: backend/README.md for HTTP API + ARCHITECTURE.md for data flow.

**Q: Where are code examples?**  
A: game/CLAUDE.md (GDScript) + DEVELOPMENT.md (Python) + backend/README.md (API examples).

---

## 📞 Maintenance

**Owner:** Gokul Kushalappa  
**Last Reviewed:** 2026-05-16  
**Review Frequency:** Quarterly or on major changes  

### Deprecation Policy
- Outdated docs are marked with ⚠️ DEPRECATED
- Maintainers update annually or when major changes occur
- Remove docs only after 2 releases

---

**This documentation is auto-generated and maintained. Last updated 2026-05-16.**
