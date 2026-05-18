extends Node

const RIVAL_GOD_SCENE = preload("res://scenes/RivalGod.tscn")
const RIVAL_SPAWN_DAY := 6
const MAX_RIVALS := 2

var _active_rivals: Array = []
var _world_root: Node = null

func _ready() -> void:
	EventBus.day_changed.connect(_on_day_changed)
	GodStats.game_over.connect(_on_game_over)
	EventBus.rival_boon_cast.connect(_on_rival_boon_cast)

func set_world_root(root: Node) -> void:
	_world_root = root

func _on_day_changed(day: int) -> void:
	# Spawn first rival on day 6
	if day == RIVAL_SPAWN_DAY and _active_rivals.size() == 0:
		_spawn_rival()

	# Spawn second rival on day 11 if player has many followers (optional scaling)
	if day == 11 and _active_rivals.size() < MAX_RIVALS and GodStats.followers > 10:
		_spawn_rival()

func _spawn_rival() -> void:
	if _world_root == null:
		push_error("RivalSpawner: world_root not set!")
		return

	var rival = RIVAL_GOD_SCENE.instantiate()
	rival.position = Vector2(512, 300)  # Center of screen
	_world_root.add_child(rival)
	_active_rivals.append(rival)
	print("Rival god spawned on day ", DayClock.current_day)

func _on_rival_boon_cast(boon_data: Dictionary, position: Vector2) -> void:
	var rival_id = boon_data.get("rival_id", 0)
	print("[RivalSpawner] Rival #%d cast boon at %v (followers: %d, DP: %.1f)" % [
		rival_id, position, GodStats.rival_followers, GodStats.rival_divine_power
	])

func _on_game_over() -> void:
	# Clean up rivals on game over
	for rival in _active_rivals:
		rival.queue_free()
	_active_rivals.clear()
