# GodStats: God's core statistics singleton
extends Node

var followers: int = 0
var divine_power: float = 20.0
var max_divine_power: float = 100.0
var god_level: int = 1
var head_preacher_cost: float = 20.0

# Shrine tracking — split into three separate concerns
var shrines_built: int = 0         # actual completed shrines
var shrine_sites_pending: int = 0  # sites placed but not yet built
var _shrine_milestones: int = 0    # how many shrine_unlocked events have fired

var xp_thresholds: Array[int] = [5, 10, 15, 20, 25, 30]

# Role population counts — updated by register_role / unregister_role
var role_counts: Dictionary = {
	"Builder": 0,
	"Gatherer": 0,
	"Farmer": 0,
	"Defender": 0,
	"Scholar": 0,
}

signal followers_changed(new_count: int)
signal divine_power_changed(new_value: float)
signal level_up(new_level: int)
signal game_over()

func add_divine_power(amount: float) -> void:
	divine_power = min(divine_power + amount, max_divine_power)
	divine_power_changed.emit(divine_power)

func spend_divine_power(amount: float) -> bool:
	if divine_power >= amount:
		divine_power -= amount
		divine_power_changed.emit(divine_power)
		return true
	return false

func add_follower() -> void:
	followers += 1
	followers_changed.emit(followers)
	check_level_up()
	var expected: int = followers / 5
	while _shrine_milestones < expected:
		_shrine_milestones += 1
		shrine_sites_pending += 1
		EventBus.shrine_unlocked.emit()

func remove_follower() -> void:
	if followers > 0:
		followers -= 1
		followers_changed.emit(followers)

func check_level_up() -> void:
	if god_level < xp_thresholds.size():
		if followers >= xp_thresholds[god_level - 1]:
			god_level += 1
			level_up.emit(god_level)

# Called when a ShrineConstructionSite completes — converts pending site to built shrine
func on_shrine_built() -> void:
	shrine_sites_pending = max(0, shrine_sites_pending - 1)
	shrines_built += 1

# Returns the role the civilization currently needs most
func assign_role() -> String:
	if role_counts["Builder"] < shrine_sites_pending * 3:
		return "Builder"
	if not get_tree().get_nodes_in_group("enemies").is_empty():
		if role_counts["Defender"] < 2:
			return "Defender"
	if shrines_built > 0 and role_counts["Farmer"] < shrines_built * 2:
		return "Farmer"
	if shrines_built > 0 and role_counts["Scholar"] < shrines_built:
		return "Scholar"
	return "Gatherer"

func register_role(role: String) -> void:
	if role in role_counts:
		role_counts[role] += 1

func unregister_role(role: String) -> void:
	if role in role_counts and role_counts[role] > 0:
		role_counts[role] -= 1
