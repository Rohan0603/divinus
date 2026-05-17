# Shrine: Sacred structure that regenerates divine power
extends StaticBody2D

var _timer: Timer

func _ready() -> void:
	add_to_group("shrines")
	_timer = Timer.new()
	add_child(_timer)
	_timer.wait_time = 5.0
	_timer.timeout.connect(_on_timer_timeout)
	_timer.start()
	EventBus.shrine_built.emit(self)

func _on_timer_timeout() -> void:
	GodStats.add_divine_power(10.0)
