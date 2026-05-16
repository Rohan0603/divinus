## GodStats — single source of truth for the player's divine metrics.
## All mutations go through setters so signals fire automatically.
extends Node

signal followers_changed(new_count: int)
signal energy_changed(new_energy: float)
signal level_up(new_level: int)
signal game_over

var max_energy: float = 100.0
var god_level: int = 1

# XP required to reach levels 2, 3, 4, 5, 6 respectively.
var xp_thresholds: Array = [100, 250, 500, 1000, 2000]

# Backing variables prevent infinite recursion inside the setters.
var _followers: int = 0
var _energy: float = 100.0
var _xp: int = 0

var followers: int:
	get: return _followers
	set(value):
		_followers = value
		followers_changed.emit(_followers)

var energy: float:
	get: return _energy
	set(value):
		_energy = clampf(value, 0.0, max_energy)
		energy_changed.emit(_energy)
		if _energy <= 0.0:
			game_over.emit()

func add_xp(amount: int) -> void:
	# Once max level is reached, surplus XP is silently discarded.
	if god_level > xp_thresholds.size():
		return
	_xp += amount
	var threshold: int = xp_thresholds[god_level - 1]
	if _xp >= threshold:
		_xp -= threshold
		god_level += 1
		level_up.emit(god_level)
