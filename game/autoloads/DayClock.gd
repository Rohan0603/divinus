# DayClock: Game day/night cycle timer
# Manages game day progression - 1 in-game day = 180 seconds (3 minutes)
# Autoload this as "DayClock" in project settings
extends Node

# === Day State ===
var current_day: int = 1

# === Internal ===
var _timer: Timer
var _warning_timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	add_child(_timer)
	_timer.wait_time = 20.0
	_timer.timeout.connect(_on_day_timeout)
	_timer.start()

	# Fires 5s before the day ends to trigger enemy raids
	_warning_timer = Timer.new()
	add_child(_warning_timer)
	_warning_timer.wait_time = 15.0
	_warning_timer.timeout.connect(_on_day_warning)
	_warning_timer.start()

func _on_day_warning() -> void:
	EventBus.day_ending.emit(current_day)

# Day timer expired - increment day and broadcast event
func _on_day_timeout() -> void:
	if current_day >= 15:
		return
	current_day += 1
	EventBus.day_changed.emit(current_day)
	if current_day >= 15:
		print("[DayClock] Day 15 reached! Player: %d followers, Rival: %d followers" % [
			GodStats.followers, GodStats.rival_followers
		])
		if GodStats.followers > GodStats.rival_followers:
			print("[DayClock] VICTORY! Player has more followers than rival")
			EventBus.day_won.emit()
		else:
			print("[DayClock] DEFEAT! Rival has more followers (or tied)")
			GodStats.game_over.emit()

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
		if GodStats.followers > GodStats.rival_followers:
			EventBus.day_won.emit()
		else:
			GodStats.game_over.emit()

	print("FastForward: Jumped to day %d" % current_day)

# Reset to day 1
func reset() -> void:
	current_day = 1
	_timer.stop()
	_timer.start()
	_warning_timer.stop()
	_warning_timer.start()

# Get seconds remaining in current day
func get_time_remaining() -> float:
	return _timer.time_left
