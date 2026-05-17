# EnemySpawner: Spawns bandit raids during the last 30 seconds of each day
# Listens to day_ending to spawn, day_changed to clear any remaining enemies
extends Node

const ENEMY_SCENE = preload("res://scenes/Enemy.tscn")

const WAVE_TABLE = {
	1:  0,
	2:  2,
	3:  3,
	4:  3,
	5:  4,
	6:  4,
	7:  5,
	8:  5,
	9:  6,
	10: 6,
}

func _ready() -> void:
	EventBus.day_ending.connect(_on_day_ending)
	EventBus.day_changed.connect(_on_day_changed)

# 30 seconds before day ends — spawn this day's raid
func _on_day_ending(day_number: int) -> void:
	var count: int = WAVE_TABLE.get(day_number, 6)
	for i in range(count):
		_spawn_bandit()

# Day rolled over — send any stragglers off the map
func _on_day_changed(_day_number: int) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.start_exit()

func _spawn_bandit() -> void:
	var bandit = ENEMY_SCENE.instantiate()
	bandit.global_position = _random_edge_position()
	get_tree().current_scene.add_child(bandit)

func _random_edge_position() -> Vector2:
	match randi() % 4:
		0: return Vector2(randf_range(50.0, 974.0), 0.0)
		1: return Vector2(randf_range(50.0, 974.0), 600.0)
		2: return Vector2(0.0, randf_range(50.0, 550.0))
		_: return Vector2(1024.0, randf_range(50.0, 550.0))
