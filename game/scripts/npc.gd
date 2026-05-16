## npc.gd — NPC behaviour driven by a lightweight state machine.
## Three states: Unaware → Witness → Follower.
## Each state is an inner class with enter() / update() / exit().
extends CharacterBody2D

## Set by Main when spawning so all NPCs share the same target.
var shrine_position: Vector2 = Vector2(512.0, 300.0)

var _state: BaseState  # currently active state object

# ---------------------------------------------------------------------------
# Base state — all concrete states inherit from this.
# Using an untyped 'host' reference avoids a forward-declaration cycle.
# ---------------------------------------------------------------------------
class BaseState:
	var host  # the NPC CharacterBody2D that owns this state

	func _init(p_host) -> void:
		host = p_host

	func enter() -> void: pass
	func update(_delta: float) -> void: pass
	func exit() -> void: pass

# ---------------------------------------------------------------------------
# Unaware — default state; NPC wanders randomly until witness_miracle() fires.
# ---------------------------------------------------------------------------
class UnawareState extends BaseState:
	var _timer: float = 0.0
	var _dir: Vector2 = Vector2.ZERO

	func enter() -> void:
		_pick_direction()

	func update(delta: float) -> void:
		_timer -= delta
		if _timer <= 0.0:
			_pick_direction()
		host.velocity = _dir * 50.0
		host.move_and_slide()

	func exit() -> void:
		host.velocity = Vector2.ZERO

	func _pick_direction() -> void:
		# Choose a uniformly random direction and a random walk duration.
		var angle: float = randf() * TAU
		_dir = Vector2(cos(angle), sin(angle))
		_timer = randf_range(1.0, 3.0)

# ---------------------------------------------------------------------------
# Witness — NPC freezes in awe; converts to Follower after a brief pause.
# ---------------------------------------------------------------------------
class WitnessState extends BaseState:
	const AWE_DURATION: float = 3.0  # seconds of stunned wonder

	var _timer: float = 0.0

	func enter() -> void:
		host.velocity = Vector2.ZERO
		_timer = AWE_DURATION

	func update(delta: float) -> void:
		_timer -= delta
		if _timer <= 0.0:
			# Hand control back to the NPC's transition method.
			host.transition_to("Follower")

	func exit() -> void: pass

# ---------------------------------------------------------------------------
# Follower — NPC walks toward the shrine; stays put once it arrives.
# ---------------------------------------------------------------------------
class FollowerState extends BaseState:
	const SPEED: float = 80.0
	const ARRIVAL_RADIUS: float = 12.0

	func enter() -> void:
		# Emit conversion event and increment global follower count.
		EventBus.npc_converted.emit(host)
		GodStats.followers += 1

	func update(_delta: float) -> void:
		var to_shrine: Vector2 = host.shrine_position - host.global_position
		# Stop moving once close enough so NPCs don't jitter at the shrine.
		if to_shrine.length() < ARRIVAL_RADIUS:
			host.velocity = Vector2.ZERO
			return
		host.velocity = to_shrine.normalized() * SPEED
		host.move_and_slide()

	func exit() -> void: pass

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	transition_to("Unaware")

func _physics_process(delta: float) -> void:
	if _state:
		_state.update(delta)

func transition_to(state_name: String) -> void:
	if _state:
		_state.exit()
	match state_name:
		"Unaware":  _state = UnawareState.new(self)
		"Witness":  _state = WitnessState.new(self)
		"Follower": _state = FollowerState.new(self)
		_:
			push_error("NPC: unknown state '%s'" % state_name)
			return
	_state.enter()

## Called externally (e.g. boon landing nearby) to trigger the conversion chain.
func witness_miracle() -> void:
	# Only Unaware NPCs can be converted; already-faithful ones are ignored.
	if _state is UnawareState:
		transition_to("Witness")
