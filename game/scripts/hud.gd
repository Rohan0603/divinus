## hud.gd — reads GodStats signals and keeps the on-screen display in sync.
extends CanvasLayer

func _ready() -> void:
	# Wait a frame to ensure child nodes are ready.
	await get_tree().process_frame

	var energy_bar = get_node_or_null("VBoxContainer/EnergyBar")
	var follower_label = get_node_or_null("VBoxContainer/FollowerLabel")
	var day_label = get_node_or_null("VBoxContainer/DayLabel")

	if not energy_bar or not follower_label or not day_label:
		push_error("HUD: missing child nodes")
		return

	# Initialize display.
	energy_bar.max_value = GodStats.max_energy
	energy_bar.value = GodStats.energy
	follower_label.text = "Followers: 0"
	day_label.text = "Day 1"

	# Connect signals.
	GodStats.energy_changed.connect(func(e): energy_bar.value = e)
	GodStats.followers_changed.connect(func(c): follower_label.text = "Followers: %d" % c)
	EventBus.day_changed.connect(func(d): day_label.text = "Day %d" % d)
