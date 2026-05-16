## main.gd — entry point for the game scene.
## Kicks off the day/night cycle and populates the world with NPCs.
extends Node2D

const NPC_SCENE: PackedScene = preload("res://scenes/NPC.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/HUD.tscn")
const NPC_COUNT: int = 5

func _ready() -> void:
	DayClock.start()
	_setup_hud()
	_spawn_npcs()

func _setup_hud() -> void:
	var hud = HUD_SCENE.instantiate()
	add_child(hud)

func _spawn_npcs() -> void:
	var vp: Vector2 = get_viewport_rect().size
	for i in NPC_COUNT:
		var npc: CharacterBody2D = NPC_SCENE.instantiate()
		npc.position = Vector2(
			randf_range(60.0, vp.x - 60.0),
			randf_range(60.0, vp.y - 60.0)
		)
		add_child(npc)
