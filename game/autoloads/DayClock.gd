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
	_timer.wait_time = 180.0
	_timer.timeout.connect(_on_day_timeout)
	_timer.start()

	# Fires 30s before the day ends to trigger enemy raids
	_warning_timer = Timer.new()
	add_child(_warning_timer)
	_warning_timer.wait_time = 150.0
	_warning_timer.timeout.connect(_on_day_warning)
	_warning_timer.start()

func _on_day_warning() -> void:
	EventBus.day_ending.emit(current_day)

# Day timer expired - increment day and broadcast event
func _on_day_timeout() -> void:
	current_day += 1
	EventBus.day_changed.emit(current_day)

# Get seconds remaining in current day
func get_time_remaining() -> float:
	return _timer.time_left
