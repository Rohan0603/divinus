# npc.gd — NPC with role-based behaviour and skill progression
# Shapes encode role identity; color encodes skill level
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
	"Unaware":     Color(0.40, 0.50, 0.90),
	"Witness":     Color(1.00, 1.00, 0.85),
	"HeadPreacher": Color(1.00, 0.85, 0.20),
	"Builder":     Color(1.00, 0.55, 0.00),
	"Gatherer":    Color(0.00, 0.70, 0.70),
	"Farmer":      Color(0.55, 0.90, 0.10),
	"Defender":    Color(0.90, 0.10, 0.10),
	"Scholar":     Color(0.35, 0.00, 0.60),
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

@onready var sprite: Polygon2D = $Polygon2D

func _ready() -> void:
	add_to_group("npcs")
	sprite.polygon = _shape_square(12.0)
	sprite.color = ROLE_COLORS["Unaware"]
	_pick_wander_target()
	EventBus.boon_cast.connect(_on_boon_cast)
	EventBus.rival_boon_cast.connect(_on_rival_boon_cast)

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

# --- Shape generators ---

func _shape_square(r: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-r, -r), Vector2(r, -r),
		Vector2(r, r),   Vector2(-r, r),
	])

func _shape_circle(r: float, n: int = 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a = TAU * i / n - PI / 2.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

func _shape_polygon(sides: int, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var a = TAU * i / sides - PI / 2.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

func _shape_triangle(r: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -r),
		Vector2(r * 0.866, r * 0.5),
		Vector2(-r * 0.866, r * 0.5),
	])

func _shape_diamond(r: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -r),
		Vector2(r * 0.75, 0.0),
		Vector2(0.0, r),
		Vector2(-r * 0.75, 0.0),
	])

func _shape_shield(r: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -r),
		Vector2(r, -r * 0.25),
		Vector2(r * 0.65, r * 0.75),
		Vector2(-r * 0.65, r * 0.75),
		Vector2(-r, -r * 0.25),
	])

func _shape_star(outer: float, inner: float, points: int = 5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points * 2:
		var a = TAU * i / (points * 2) - PI / 2.0
		var rad = outer if i % 2 == 0 else inner
		pts.append(Vector2(cos(a), sin(a)) * rad)
	return pts

func _apply_shape(r: String) -> void:
	match r:
		"HeadPreacher": sprite.polygon = _shape_star(14.0, 6.0)
		"Builder":      sprite.polygon = _shape_triangle(14.0)
		"Gatherer":     sprite.polygon = _shape_circle(12.0)
		"Farmer":       sprite.polygon = _shape_diamond(14.0)
		"Defender":     sprite.polygon = _shape_shield(13.0)
		"Scholar":      sprite.polygon = _shape_polygon(6, 13.0)

# --- State updates ---

func _update_unaware(delta: float) -> void:
	_wander(delta)

func _update_witness(delta: float) -> void:
	velocity = Vector2.ZERO
	faith += FAITH_RATE * delta
	if faith >= FAITH_THRESHOLD:
		_become_follower()

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

func _update_gatherer(delta: float) -> void:
	_wander(delta)
	_income_timer -= delta
	if _income_timer <= 0.0:
		_income_timer = INCOME_INTERVAL
		GodStats.add_divine_power(3.0 * _efficiency())
		_gain_xp(INCOME_XP)

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

func _update_defender(delta: float) -> void:
	var enemy := _find_nearest_enemy()
	if enemy == null:
		_wander(delta)
		return

	velocity = (enemy.global_position - global_position).normalized() * SPEED
	if global_position.distance_to(enemy.global_position) < 40.0:
		enemy.start_exit()
		_gain_xp(INCOME_XP)

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
	_wander_target = Vector2(randf_range(-1200.0, 2200.0), randf_range(200.0, 2300.0))

# --- Conversion ---

func witness_miracle() -> void:
	if current_state == "Unaware":
		current_state = "Witness"
		sprite.polygon = _shape_circle(12.0)
		sprite.color = ROLE_COLORS["Witness"]
		faith = 0.0

func _become_follower() -> void:
	add_to_group("followers")
	GodStats.add_follower()
	EventBus.npc_converted.emit(self)
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
	_apply_shape(role)
	sprite.color = ROLE_COLORS.get(role, Color.WHITE)
	_income_timer = INCOME_INTERVAL
	_conversion_target = null

func take_damage(attacker: Node = null) -> void:
	if current_state == "Unaware" or current_state == "Witness":
		return
	# Knockback velocity away from attacker
	if attacker != null:
		var knockback_direction = (global_position - attacker.global_position).normalized()
		velocity = knockback_direction * 300.0
	if role == "Builder":
		_leave_site()
	if role != "" and role != "HeadPreacher":
		GodStats.unregister_role(role)
	role = ""
	remove_from_group("followers")
	GodStats.remove_follower()
	current_state = "Unaware"
	faith = 0.0
	sprite.polygon = _shape_square(12.0)
	sprite.color = ROLE_COLORS["Unaware"]
	_pick_wander_target()

# Combat feedback: Flash white briefly and scale punchback
func hit_flash() -> void:
	var orig_scale = sprite.scale
	var orig_color = sprite.color
	sprite.color = Color.WHITE
	sprite.scale = orig_scale * 1.2
	await get_tree().create_timer(0.1).timeout
	sprite.scale = orig_scale * 0.95
	await get_tree().create_timer(0.1).timeout
	sprite.color = orig_color
	sprite.scale = orig_scale

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

func _on_boon_cast(_boon_data: Dictionary, pos: Vector2) -> void:
	if current_state == "Unaware" and global_position.distance_to(pos) <= BOON_RADIUS:
		witness_miracle()

func _on_rival_boon_cast(boon_data: Dictionary, position: Vector2) -> void:
	if current_state == "Unaware":
		var distance = global_position.distance_to(position)
		if distance <= BOON_RADIUS:
			var rival_id = boon_data.get("rival_id", 0)
			print("[NPC] Converted to rival #%d follower (distance: %.1f, total rival followers: %d)" % [
				rival_id, distance, GodStats.rival_followers + 1
			])
			_become_rival_follower(rival_id)

func _become_rival_follower(rival_id: int) -> void:
	current_state = "Witness"
	role = ""
	GodStats.add_rival_follower()
	if sprite:
		sprite.color = Color.CYAN
