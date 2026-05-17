# Enemy: Bandit that raids at the end of each day
# Hunts the nearest follower NPC, deals damage on contact, then exits the map
# Also exits when the day rolls over (sent off by EnemySpawner)
extends CharacterBody2D

const MOVEMENT_SPEED = 80.0
const EXIT_SPEED = 120.0
const CONTACT_DISTANCE = 30.0
const DAMAGE_COOLDOWN = 1.0

var is_exiting: bool = false
var _exit_target: Vector2
var _damage_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if is_exiting:
		velocity = (_exit_target - global_position).normalized() * EXIT_SPEED
		move_and_slide()
		if global_position.distance_to(_exit_target) < 20.0:
			queue_free()
		return

	_damage_timer -= delta
	_hunt_nearest_follower()
	move_and_slide()

func _hunt_nearest_follower() -> void:
	var followers = get_tree().get_nodes_in_group("followers")
	if followers.is_empty():
		velocity = Vector2.ZERO
		return

	var nearest: Node = null
	var nearest_dist: float = INF
	for f in followers:
		var d = global_position.distance_to(f.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = f

	if nearest == null:
		velocity = Vector2.ZERO
		return

	velocity = (nearest.global_position - global_position).normalized() * MOVEMENT_SPEED

	if nearest_dist < CONTACT_DISTANCE and _damage_timer <= 0.0:
		nearest.take_damage()
		start_exit()

# Walk toward the nearest map edge, then despawn
func start_exit() -> void:
	if is_exiting:
		return
	is_exiting = true
	var candidates = [
		Vector2(global_position.x, -60.0),
		Vector2(global_position.x, 660.0),
		Vector2(-60.0, global_position.y),
		Vector2(1084.0, global_position.y),
	]
	_exit_target = candidates[0]
	for c in candidates:
		if global_position.distance_to(c) < global_position.distance_to(_exit_target):
			_exit_target = c
