# HUD: Heads-up display showing god stats and day timer
extends CanvasLayer

@onready var divine_power_label: Label = $VBoxContainer/DivinePowerLabel
@onready var followers_label: Label = $VBoxContainer/FollowersLabel
@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var day_label: Label = $VBoxContainer/DayLabel

func _ready() -> void:
	GodStats.divine_power_changed.connect(_on_divine_power_changed)
	GodStats.followers_changed.connect(_on_followers_changed)
	GodStats.level_up.connect(_on_level_up)
	EventBus.day_changed.connect(_on_day_changed)

	_on_divine_power_changed(GodStats.divine_power)
	_on_followers_changed(GodStats.followers)
	_on_level_up(GodStats.god_level)

func _process(_delta: float) -> void:
	var t = DayClock.get_time_remaining()
	day_label.text = "Day: %d | Time: %d:%02d" % [DayClock.current_day, int(t) / 60, int(t) % 60]

func _on_divine_power_changed(new_value: float) -> void:
	divine_power_label.text = "Divine Power: %.0f / %.0f" % [new_value, GodStats.max_divine_power]

func _on_followers_changed(new_count: int) -> void:
	followers_label.text = "Followers: %d" % new_count

func _on_level_up(new_level: int) -> void:
	level_label.text = "Level: %d" % new_level

func _on_day_changed(_day_number: int) -> void:
	pass
