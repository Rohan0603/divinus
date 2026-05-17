# Godot Extensions & Development Setup

## 1. Godot Asset Library Addons (Recommended for Divinus)

Install via **Godot Editor → AssetLib** or download to `res://addons/`:

### Productivity & Debugging
- **Debug Console Enhanced** — Better debugging output (REPL-like console)
- **GDScript Formatter** — Auto-format code with Alt+Shift+F
- **Better Comments** — Syntax highlighting for TODO/FIXME/NOTE comments

### Game Development Utilities
- **Movement Recorder** — Record NPC paths for testing (useful for Divinus)
- **Tween Manager** — Simplified animation system (for boon effects)
- **Finite State Machine (FSM)** — Advanced state machine (optional — we have inner classes)

### UI & HUD
- **Rich Text Label Extensions** — Better text rendering for dialogue (post-MVP)

### Optional (Post-MVP)
- **Dialogue Manager** — NPC dialogue system (ties into LLM integration later)
- **Godot Procedural Generation Toolkit** — For terrain generation (Phase 2+)
- **Godot Path Finder** — A* pathfinding for enemy AI (Day 10+ waves)

### Installation Steps
1. Open Godot Editor
2. Go to **AssetLib** tab (top)
3. Search addon name
4. Click **Download** → **Install**
5. Enable in **Project → Project Settings → Plugins**

---

## 2. Claude Code Skills for Godot Development

### Use These Skills (Available Now)

```bash
ecc:feature-dev      # Use when implementing game features
ecc:code-review      # Use after writing GDScript
ecc:plan             # Use for architecture planning
ecc:refactor-clean   # Use to clean up dead code
ecc:test-coverage    # Use to check test coverage
ecc:security-review  # Use for sensitive systems (save/load)
```

### Recommended Workflow
1. **Start feature** → invoke `ecc:feature-dev` skill
2. **Write code** → use `ecc:code-review` after
3. **Refactor** → use `ecc:refactor-clean` if needed
4. **Plan big changes** → use `ecc:plan` before coding

---

## 3. VS Code Extensions for GDScript

If you use VS Code for editing (alongside Godot Editor):

### Essential
- **GDScript (godotengine.godot-tools)** — Official Godot extension
  - Syntax highlighting
  - IntelliSense
  - Debugging integration with Godot

- **GDScript Formatter** — Auto-format on save
  - Extension: `Razoric.gdscript-formatter`

### Recommended
- **Better Comments** — Highlight TODO/FIXME/NOTE
  - Extension: `Aaron-Bond.better-comments`

- **GitLens** — Git blame & history
  - Extension: `eamodio.gitlens`

- **Godot Tools** — Godot debugging in VS Code
  - Extension: `geequlim.godot-tools`

### Installation
```powershell
code --install-extension godotengine.godot-tools
code --install-extension Razoric.gdscript-formatter
code --install-extension Aaron-Bond.better-comments
```

---

## 4. Godot Project Addons Built-In (Godot 4.6)

**Already available — no install needed:**
- ✅ **Animated Sprite System** — Use for NPC sprites (post-MVP)
- ✅ **TileMap Editor** — For building world (Phase 2)
- ✅ **Animation Player** — Timeline animations
- ✅ **Physics 2D** — CharacterBody2D, Area2D, collision detection
- ✅ **Signals** — Event system (we use heavily)
- ✅ **Resources (.tres)** — Data files (for BoonData, etc.)

---

## 5. Development Workflow (Recommended)

### Daily Setup
1. **Launch Godot** with console for debugging
2. **Open VS Code** (optional) alongside Godot for editing
3. **Use Claude Code** for planning, writing, and reviewing code

### Testing in Godot Console
```gdscript
# Test NPC conversion
get_tree().get_first_child_in_group("npcs").witness_miracle()

# Test follower count
print(GodStats.followers)

# Test divine power system
GodStats.add_divine_power(-10.0)
print(GodStats.divine_power)
```

---

## 6. Performance Optimization Tools

For later phases (Phase 9+):

- **Profiler** (built-in) — `Debug → Monitor` in Godot
- **Remote Debugger** (built-in) — Connect VS Code to running Godot

---

## 7. Quick Setup Checklist

- [ ] Godot 4.6.2 installed
- [ ] Project opens without crashing
- [ ] Green NPCs spawn and wander
- [ ] VS Code installed with GDScript extension (optional)
- [ ] One Godot addon installed (Debug Console Enhanced or Formatter)

---

## 8. Install First Addon: GDScript Formatter

**In Godot Editor:**
1. Click **AssetLib** tab (top of editor)
2. Search: `gdscript formatter`
3. Click result → **Download**
4. Click **Install**
5. Go to **Project → Project Settings → Plugins**
6. Find "GDScript Formatter" → toggle **ON**
7. Restart Godot

**Now in editor:** Select any `.gd` file → **Alt+Shift+F** = auto-format

---

*Next: Start Phase 2 (TileMap world). Ask Claude Code to use `ecc:feature-dev` skill.*
