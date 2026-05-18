# Boon: Divine manifestation cast at a world position
# Notifies nearby NPCs via EventBus, fades out, then frees itself
extends Area2D

func _ready() -> void:
	# Broadcast so every NPC can self-check distance and react
	EventBus.boon_cast.emit({}, global_position)

	# Pulsing scale animation
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.set_trans(Tween.TRANS_SINE)
	pulse_tween.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property($Visual, "scale", Vector2(1.2, 1.2), 0.6)
	pulse_tween.tween_property($Visual, "scale", Vector2(0.8, 0.8), 0.6)

	# Fade out the visual ring, then remove from scene
	var tween = create_tween()
	tween.tween_property($Visual, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
