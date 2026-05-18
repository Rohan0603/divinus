extends CanvasLayer

func _ready() -> void:
	$VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)

func _on_restart_pressed() -> void:
	GodStats.reset()
	DayClock.reset()
	get_tree().reload_current_scene()
