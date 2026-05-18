# hud.gd
# HUD script: displays god stats and day/time information.
# Reacts to GodStats signals and DayClock updates in real time.

extends CanvasLayer

# Label references
@onready var energy_label: Label = $VBoxContainer/DivinePowerLabel
@onready var followers_label: Label = $VBoxContainer/FollowersLabel
@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var rival_label: Label = $VBoxContainer/RivalLabel
@onready var fastforward_notification_label: Label = $FastForwardNotificationLabel

# Notification system
var _notification_fade_timer: float = 0.0

func _ready() -> void:
	# Connect to GodStats signals
	GodStats.divine_power_changed.connect(_on_energy_changed)
	GodStats.followers_changed.connect(_on_followers_changed)
	GodStats.level_up.connect(_on_level_up)

	# Connect to EventBus day change signal
	EventBus.day_changed.connect(_on_day_changed)

	# Connect to rival stats changes
	GodStats.rival_stats_changed.connect(_on_rival_stats_changed)

	# Increase font size to 24pt for all labels
	var font_size = 24
	energy_label.add_theme_font_size_override("font_size", font_size)
	followers_label.add_theme_font_size_override("font_size", font_size)
	level_label.add_theme_font_size_override("font_size", font_size)
	day_label.add_theme_font_size_override("font_size", font_size)
	rival_label.add_theme_font_size_override("font_size", font_size)

	# Initialize labels with current values
	_on_energy_changed(GodStats.divine_power)
	_on_followers_changed(GodStats.followers)
	_on_level_up(GodStats.god_level)
	_on_day_changed(DayClock.current_day)
	_on_rival_stats_changed()

	print("HUD initialized")

func _process(delta: float) -> void:
	# Update day timer every frame
	var time_remaining = DayClock.get_time_remaining()
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	day_label.text = "Day: %d | Time: %d:%02d" % [DayClock.current_day, minutes, seconds]

	# Fade out notification
	if _notification_fade_timer > 0.0:
		_notification_fade_timer -= delta
		if _notification_fade_timer <= 0.0:
			fastforward_notification_label.modulate.a = 0.0
		else:
			# Fade from opaque to transparent over 2 seconds
			fastforward_notification_label.modulate.a = _notification_fade_timer / 2.0

# Called when energy changes
func _on_energy_changed(new_energy: float) -> void:
	energy_label.text = "Energy: %.1f / %.1f" % [new_energy, GodStats.max_divine_power]

# Called when followers count changes
func _on_followers_changed(new_count: int) -> void:
	followers_label.text = "Followers: %d" % new_count

# Called when god levels up
func _on_level_up(new_level: int) -> void:
	level_label.text = "Level: %d" % new_level

# Called when day changes
func _on_day_changed(day_number: int) -> void:
	# This is handled in _process(), but we can log it
	print("Day changed to: ", day_number)

# Called when rival stats change
func _on_rival_stats_changed() -> void:
	rival_label.text = "Rival: %d followers" % GodStats.rival_followers

func _show_notification(text: String) -> void:
	fastforward_notification_label.text = text
	fastforward_notification_label.modulate.a = 1.0
	_notification_fade_timer = 2.0  # Show for 2 seconds

func _input(event: InputEvent) -> void:
	# Fastforward controls for testing
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			if event.shift_pressed:
				# Shift+T: Jump to day 15 (win condition)
				DayClock.skip_to_day(15)
				_show_notification("Jumped to day 15")
				get_tree().root.set_input_as_handled()
			else:
				# T: Skip to next day
				var next_day = DayClock.current_day + 1
				DayClock.skip_to_day(next_day)
				_show_notification("Day +1 (now day %d)" % next_day)
				get_tree().root.set_input_as_handled()
