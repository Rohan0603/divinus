## DayClock — tracks real elapsed time and converts it to in-game days.
## One in-game day = DAY_DURATION real seconds.
## Call start() from Main once the scene tree is ready.
extends Node

const DAY_DURATION: float = 180.0  # seconds per in-game day

var current_day: int = 0
var _elapsed: float = 0.0
var _running: bool = false

func start() -> void:
	_running = true

func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	# Subtract rather than reset so partial seconds carry over to the next day.
	if _elapsed >= DAY_DURATION:
		_elapsed -= DAY_DURATION
		current_day += 1
		EventBus.day_changed.emit(current_day)
