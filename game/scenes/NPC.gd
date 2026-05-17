# npc.gd — NPC with role-based behaviour and skill progression
extends CharacterBody2D

const SPEED := 80.0
const FAITH_RATE := 3.0
const FAITH_THRESHOLD := 10.0
const BOON_RADIUS := 200.0
const ARRIVE_DIST := 24.0
const INCOME_INTERVAL := 5.0
const INCOME_XP := 10.0
const XP_PER_LEVEL := 100.0
const MAX_SKILL_LEVEL := 5
const PREACHER_RANGE := 32.0

const ROLE_COLORS := {
	"HeadPreacher": Color(1.0, 0.85, 0.2),
	"Builder": Color(1.0, 0.55, 0.0),
	"Gatherer": Color(0.0, 0.7, 0.7),
	"Farmer": Color(0.55, 0.9, 0.1),
	"Defender": Color(0.9, 0.1, 0.1),
	"Scholar": Color(0.35, 0.0, 0.6),
}

var current_state: String = "Unaware"
var faith: float = 0.0
var role: String = ""
var skill_level: int = 0
var skill_xp: float = 0.0

var _wander_target: Vector2 = Vector2.ZERO
var _idle_timer: float = 0.0
var _income_timer: float = 0.0
var _conversion_target: Node = null
var _current_site: Node = null
var _at_site: bool = false

@onready var sprite: ColorRect = $ColorRect

func _ready() -> void:
	add_to_group("npcs")
	sprite.color = Color.BLUE
	_pick_wander_target()
	EventBus.boon_cast.connect(_on_boon_cast)

func _physics_process(delta: float) -> void:
	match current_state:
		"Unaware":      _update_unaware(delta)
		"Witness":      _update_witness(delta)
		"HeadPreacher": _update_head_preacher(delta)
		"Builder":      _update_builder(delta)
		"Gatherer":     _update_gatherer(delta)
		"Farmer":       _update_farmer(delta)
		"Defender":     _update_defender(delta)
		"Scholar":      _update_scholar(delta)
	move_and_slide()

# --- Unaware: blue, random wander ---

func _update_unaware(delta: float) -> void:
	_wander(delta)

# --- Witness: yellow, accumulate faith ---

func _update_witness(delta: float) -> void:
	velocity = Vector2.ZERO
	faith += FAITH_RATE * delta
	if faith >= FAITH_THRESHOLD:
		_become_follower()

# --- Head Preacher: golden, hunts unaware NPCs ---

func _update_head_preacher(delta: float) -> void:
	if not is_instance_valid(_conversion_target) or _conversion_target.current_state != "Unaware":
		_conversion_target = _find_nearest_unaware()

	if _conversion_target == null:
		_wander(delta)
		return

	if global_position.distance_to(_conversion_target.global_position) < PREACHER_RANGE:
		_conversion_target.witness_miracle()
		_conversion_target = null
	else:
		velocity = (_conversion_target.global_position - global_position).normalized() * SPEED

# --- Builder: orange, walks to construction site ---

func _update_builder(delta: float) -> void:
	if not is_instance_valid(_current_site):
		_at_site = false
		_current_site = null

	var site := _find_nearest_shrine_site()
	if site == null:
		_assign_role()
		return

	if _current_site != site:
		_leave_site()
		_current_site = site

	var dist := global_position.distance_to(_current_site.global_position)
	if dist < ARRIVE_DIST:
		velocity = Vector2.ZERO
		if not _at_site:
			_at_site = true
			_current_site.builder_arrived()
	else:
		if _at_site:
			_at_site = false
			_current_site.builder_left()
		velocity = (_current_site.global_position - global_position).normalized() * SPEED

func _leave_site() -> void:
	if _at_site and is_instance_valid(_current_site):
		_current_site.builder_left()
	_at_site = false
	_current_site = null

# --- Gatherer: teal, wander + DP income ---

func _update_gatherer(delta: float) -> void:
	_wander(delta)
	_income_timer -= delta
	if _income_timer <= 0.0:
		_income_timer = INCOME_INTERVAL
		GodStats.add_divine_power(3.0 * _efficiency())
		_gain_xp(INCOME_XP)

# --- Farmer: yellow-green, orbit shrine + DP income ---

func _update_farmer(delta: float) -> void:
	var shrine := _find_nearest_shrine()
	if shrine == null:
		_set_role("Gatherer")
		return

	var dist := global_position.distance_to(shrine.global_position)
	if dist > 80.0:
		velocity = (shrine.global_position - global_position).normalized() * SPEED
	elif dist < 40.0:
		velocity = (global_position - shrine.global_position).normalized() * SPEED * 0.5
	else:
		velocity = Vector2.ZERO

	_income_timer -= delta
	if _income_timer <= 0.0:
		_income_timer = INCOME_INTERVAL
		GodStats.add_divine_power(4.0 * _efficiency())
		_gain_xp(INCOME_XP)

# --- Defender: red, chases enemies and forces them to flee ---

func _update_defender(delta: float) -> void:
	var enemy := _find_nearest_enemy()
	if enemy == null:
		_wander(delta)
		return

	velocity = (enemy.global_position - global_position).normalized() * SPEED
	if global_position.distance_to(enemy.global_position) < 40.0:
		enemy.start_exit()
		_gain_xp(INCOME_XP)

# --- Scholar: deep purple, near shrine + DP income ---

func _update_scholar(delta: float) -> void:
	var shrine := _find_nearest_shrine()
	if shrine == null:
		_set_role("Gatherer")
		return

	var dist := global_position.distance_to(shrine.global_position)
	if dist > 48.0:
		velocity = (shrine.global_position - global_position).normalized() * SPEED * 0.6
	else:
		velocity = Vector2.ZERO

	_income_timer -= delta
	if _income_timer <= 0.0:
		_income_timer = INCOME_INTERVAL
		GodStats.add_divine_power(2.5 * _efficiency())
		_gain_xp(INCOME_XP)

# --- Wander helper ---

func _wander(delta: float) -> void:
	if _idle_timer > 0.0:
		_idle_timer -= delta
		velocity = Vector2.ZERO
		return

	if global_position.distance_to(_wander_target) < ARRIVE_DIST:
		_idle_timer = randf_range(1.5, 3.0)
		_pick_wander_target()
	else:
		velocity = (_wander_target - global_position).normalized() * SPEED

func _pick_wander_target() -> void:
	_wander_target = Vector2(randf_range(80.0, 944.0), randf_range(80.0, 520.0))

# --- Conversion ---

func witness_miracle() -> void:
	if current_state == "Unaware":
		current_state = "Witness"
		sprite.color = Color.YELLOW
		faith = 0.0

func _become_follower() -> void:
	add_to_group("followers")
	GodStats.add_follower()
	EventBus.npc_converted.emit(self)
	# assign_head_preacher() may have been called synchronously during the emit above
	if current_state != "HeadPreacher":
		_assign_role()

func assign_head_preacher() -> void:
	_set_role("HeadPreacher")

func _assign_role() -> void:
	_set_role(GodStats.assign_role())

func _set_role(new_role: String) -> void:
	if role == "Builder":
		_leave_site()
	if role != "" and role != "HeadPreacher":
		GodStats.unregister_role(role)
	role = new_role
	if role != "" and role != "HeadPreacher":
		GodStats.register_role(role)
	current_state = role
	sprite.color = ROLE_COLORS.get(role, Color.WHITE)
	_income_timer = INCOME_INTERVAL
	_conversion_target = null

# --- Damage ---

func take_damage() -> void:
	if current_state == "Unaware" or current_state == "Witness":
		return
	if role == "Builder":
		_leave_site()
	if role != "" and role != "HeadPreacher":
		GodStats.unregister_role(role)
	role = ""
	remove_from_group("followers")
	GodStats.remove_follower()
	current_state = "Unaware"
	faith = 0.0
	sprite.color = Color.BLUE
	_pick_wander_target()

# --- Skill ---

func _efficiency() -> float:
	return 1.0 + float(skill_level) / float(MAX_SKILL_LEVEL)

func _gain_xp(amount: float) -> void:
	if skill_level >= MAX_SKILL_LEVEL:
		return
	skill_xp += amount
	if skill_xp >= XP_PER_LEVEL:
		skill_xp -= XP_PER_LEVEL
		skill_level += 1

# --- Finders ---

func _find_nearest_unaware() -> Node:
	var best: Node = null
	var best_dist := INF
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc == self or npc.current_state != "Unaware":
			continue
		var d := global_position.distance_to(npc.global_position)
		if d < best_dist:
			best_dist = d
			best = npc
	return best

func _find_nearest_shrine_site() -> Node:
	var best: Node = null
	var best_dist := INF
	for s in get_tree().get_nodes_in_group("shrine_sites"):
		if not is_instance_valid(s):
			continue
		var d := global_position.distance_to(s.global_position)
		if d < best_dist:
			best_dist = d
			best = s
	return best

func _find_nearest_shrine() -> Node:
	var best: Node = null
	var best_dist := INF
	for s in get_tree().get_nodes_in_group("shrines"):
		if not is_instance_valid(s):
			continue
		var d := global_position.distance_to(s.global_position)
		if d < best_dist:
			best_dist = d
			best = s
	return best

func _find_nearest_enemy() -> Node:
	var best: Node = null
	var best_dist := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best

# --- Signal handler ---

func _on_boon_cast(_boon_data: Dictionary, pos: Vector2) -> void:
	if current_state == "Unaware" and global_position.distance_to(pos) <= BOON_RADIUS:
		witness_miracle()
