extends Node2D

const BOON_COST := 20.0
const BOON_RADIUS := 200.0
const BOON_CAST_INTERVAL := 8.0
const BOON_SPAWN_OFFSET := 50.0

var _rival_id: int = 0

func _ready() -> void:
	_rival_id = randi() % 1000
	$BoonCastTimer.timeout.connect(_on_boon_cast_timer)
	$BoonCastTimer.start()

	# Start with 30 DP
	GodStats.add_rival_divine_power(30.0)

func _on_boon_cast_timer() -> void:
	if GodStats.rival_divine_power >= BOON_COST:
		GodStats.add_rival_divine_power(-BOON_COST)
		var boon_pos = Vector2(
			randf_range(BOON_SPAWN_OFFSET, 1024.0 - BOON_SPAWN_OFFSET),
			randf_range(BOON_SPAWN_OFFSET, 600.0 - BOON_SPAWN_OFFSET)
		)
		print("[RivalGod #%d] Cast boon at %v (DP: %.1f → %.1f)" % [
			_rival_id, boon_pos, GodStats.rival_divine_power + BOON_COST, GodStats.rival_divine_power
		])
		EventBus.rival_boon_cast.emit({"rival_id": _rival_id}, boon_pos)

func _on_game_over() -> void:
	queue_free()
