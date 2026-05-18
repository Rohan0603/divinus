# Fastforward Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a keyboard-triggered fastforward mechanism to skip days during testing, allowing testers to quickly reach day 6 (rival spawn) and day 15 (win condition).

**Architecture:** 
- Add `skip_to_day(target_day: int)` method to DayClock autoload to immediately set the current day and emit signals as if the day had progressed naturally.
- Add fastforward controls to HUD (or main scene input) that trigger day skips: **T** key cycles day +1, **Shift+T** jumps to day 15.
- Ensure rival spawner, enemy spawner, and day-dependent logic all respond correctly to skipped days.

**Tech Stack:** Godot 4.6 GDScript, signal-driven day progression via DayClock.

---

## File Structure

**Modified Files:**
- `autoloads/DayClock.gd` — Add `skip_to_day()` method and day jump logic
- `scenes/HUD.gd` — Add keyboard input handlers for fastforward keys (T, Shift+T)

**No new files needed** — UI will use existing HUD or simple print notifications.

---

## Task 1: Add skip_to_day() Method to DayClock

**Files:** Modify `autoloads/DayClock.gd:40-end`

Add a public method that teleports to a specific day and emits all required signals.

- [ ] **Step 1: Read the current DayClock.gd to understand timer state**

Current DayClock has:
- `_timer` with 180s wait_time
- `_warning_timer` with 150s wait_time
- `current_day` variable
- Signals: `EventBus.day_ending`, `EventBus.day_changed`, `EventBus.day_won`

When skipping days, we need to:
1. Set `current_day` to target
2. Reset both timers
3. Emit `day_ending` (30s warning) for each intermediate day
4. Emit `day_changed` for the target day
5. Emit `day_won` if target >= 15

- [ ] **Step 2: Write the skip_to_day() implementation**

Add this method to DayClock.gd after the `_on_day_timeout` function:

```gdscript
# Jump directly to a specific day, emitting all signals as if days had progressed
func skip_to_day(target_day: int) -> void:
	if target_day <= current_day:
		print("FastForward: Already at or past day %d" % target_day)
		return
	
	# Emit day_ending for each intermediate day
	for day in range(current_day, target_day):
		EventBus.day_ending.emit(day)
	
	# Jump to target day
	current_day = target_day
	
	# Reset timers to full duration
	_timer.stop()
	_timer.start()
	_warning_timer.stop()
	_warning_timer.start()
	
	# Emit day_changed for the target day
	EventBus.day_changed.emit(current_day)
	
	# Check win condition
	if current_day >= 15:
		EventBus.day_won.emit()
	
	print("FastForward: Jumped to day %d" % current_day)
```

- [ ] **Step 3: Verify syntax by reading the updated section**

Run a quick read to ensure the method is properly indented and placed.

- [ ] **Step 4: Commit**

```bash
git add game/autoloads/DayClock.gd
git commit -m "feat: add skip_to_day() method to DayClock for testing"
```

---

## Task 2: Add Fastforward Input Handling to HUD

**Files:** Modify `scenes/HUD.gd`

Add keyboard input handlers in the HUD script to trigger day skipping.

- [ ] **Step 1: Read HUD.gd to understand current structure**

Check if HUD.gd already has `_input()` or `_process()` methods.

- [ ] **Step 2: Add _input() handler or extend existing one**

If no `_input()` method exists, add this to HUD.gd (in the script body, after any existing methods):

```gdscript
func _input(event: InputEvent) -> void:
	# Fastforward controls for testing
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			if event.shift_pressed:
				# Shift+T: Jump to day 15 (win condition)
				DayClock.skip_to_day(15)
				get_tree().root.set_input_as_handled()
			else:
				# T: Skip to next day
				DayClock.skip_to_day(DayClock.current_day + 1)
				get_tree().root.set_input_as_handled()
```

If `_input()` already exists in HUD.gd, add the above code block into it before the final `}`.

- [ ] **Step 3: Verify the logic**

- **T** key: `skip_to_day(current_day + 1)` → advances by 1 day
- **Shift+T** key: `skip_to_day(15)` → jumps to day 15
- `get_tree().root.set_input_as_handled()` prevents input from propagating to game

- [ ] **Step 4: Commit**

```bash
git add game/scenes/HUD.gd
git commit -m "feat: add T/Shift+T fastforward keyboard controls to HUD"
```

---

## Task 3: Test Fastforward in Game

**Files:** Test in running game

Run the game and verify day skipping works end-to-end.

- [ ] **Step 1: Launch the game**

Open Godot editor and run `scenes/Main.tscn`, or use MCP:
```bash
project_run op="run"
```

- [ ] **Step 2: Test T key (advance +1 day)**

Press T key once. Observe:
- HUD day counter increments by 1
- Timers reset (no stutter or hang)
- No errors in Godot console

Expected: Day goes from 1 → 2 (or current → current+1)

- [ ] **Step 3: Test Shift+T key (jump to day 15)**

From day 1, press Shift+T. Observe:
- HUD day counter jumps to 15
- Win screen appears immediately
- Game does not crash

Expected: Win screen displays, allowing restart.

- [ ] **Step 4: Test rapid T presses**

Press T 5 times rapidly to reach day 6. Observe:
- Day counter increments 1, 2, 3, 4, 5, 6
- Around day 6, check if rival god spawns (should see new agent or cyan boons)
- No console errors

Expected: Rival appears on day 6 as per design.

- [ ] **Step 5: Test day_ending signal chain**

From day 1, press T to reach day 7. Observe:
- Each intermediate day should have triggered day_ending signal
- Enemy spawner should have reacted correctly
- No errors related to enemy spawning

Expected: Each day's events fire correctly even when skipped.

- [ ] **Step 6: Commit test results**

```bash
git add -A
git commit -m "test: verify fastforward T/Shift+T controls work end-to-end"
```

---

## Task 4: (Optional) Add On-Screen Notification

**Files:** Modify `scenes/HUD.tscn` and `scenes/HUD.gd`

Add a small label that displays fastforward notifications (e.g., "Day +1" or "Jumped to day 15").

- [ ] **Step 1: Open HUD.tscn and add a Label node**

In the scene tree, add a new Label (e.g., name it `FastForwardNotificationLabel`):
- Position: top-left, e.g., (10, 10)
- Text: (leave empty for now)
- Add a modulate property: set alpha to 0 (invisible by default)

- [ ] **Step 2: Update HUD.gd with notification logic**

Add at the top of HUD.gd:

```gdscript
@onready var fastforward_notification_label = $FastForwardNotificationLabel
var _notification_fade_timer: float = 0.0
```

Update the `_input()` method to show notifications:

```gdscript
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			if event.shift_pressed:
				DayClock.skip_to_day(15)
				_show_notification("Jumped to day 15")
				get_tree().root.set_input_as_handled()
			else:
				var next_day = DayClock.current_day + 1
				DayClock.skip_to_day(next_day)
				_show_notification("Day +1 (now day %d)" % next_day)
				get_tree().root.set_input_as_handled()

func _show_notification(text: String) -> void:
	fastforward_notification_label.text = text
	fastforward_notification_label.modulate.a = 1.0
	_notification_fade_timer = 2.0  # Show for 2 seconds

func _process(delta: float) -> void:
	# Fade out notification
	if _notification_fade_timer > 0.0:
		_notification_fade_timer -= delta
		if _notification_fade_timer <= 0.0:
			fastforward_notification_label.modulate.a = 0.0
		else:
			# Fade from opaque to transparent
			fastforward_notification_label.modulate.a = _notification_fade_timer / 2.0
```

- [ ] **Step 3: Test the notification**

Run the game and press T. The label should appear with "Day +1" and fade after 2 seconds.

- [ ] **Step 4: Commit**

```bash
git add game/scenes/HUD.tscn game/scenes/HUD.gd
git commit -m "feat: add fastforward notification label that fades after 2s"
```

---

## Verification Checklist

After completing all tasks:

- [ ] T key advances day by 1
- [ ] Shift+T jumps directly to day 15
- [ ] Day counter in HUD updates correctly
- [ ] Timers reset after skip (no hanging)
- [ ] Rival spawns when skipping past day 6
- [ ] Win screen appears on day 15
- [ ] No console errors during rapid T presses
- [ ] Game is playable/testable in under 30 seconds (goal: reach win condition)
- [ ] All changes committed with clear messages
