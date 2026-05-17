# Boon: Divine manifestation cast at a world position
# Notifies nearby NPCs via EventBus, fades out, then frees itself
extends Area2D

func _ready() -> void:
	# Broadcast so every NPC can self-check distance and react
	EventBus.boon_cast.emit({}, global_position)

	# Fade out the visual ring, then remove from scene
	var tween = create_tween()
	tween.tween_property($Visual, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
