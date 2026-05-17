# main.gd — Root game script
extends Node2D

const NPC_SCENE := preload("res://scenes/NPC.tscn")
const SHRINE_CONSTRUCTION_SCENE := preload("res://scenes/ShrineConstructionSite.tscn")
const SHRINE_SCENE := preload("res://scenes/Shrine.tscn")
const BOON_SCENE := preload("res://scenes/Boon.tscn")

const NUM_STARTING_NPCS := 6
const BOON_COST := 5.0

var _head_preacher_assigned := false

func _ready() -> void:
	EventBus.shrine_unlocked.connect(_on_shrine_unlocked)
	EventBus.npc_converted.connect(_on_npc_converted)
	GodStats.game_over.connect(_on_game_over)
	_spawn_npcs()

func _spawn_npcs() -> void:
	for i in range(NUM_STARTING_NPCS):
		var npc := NPC_SCENE.instantiate()
		npc.position = Vector2(randf_range(100.0, 924.0), randf_range(100.0, 500.0))
		add_child(npc)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GodStats.spend_divine_power(BOON_COST):
			var boon := BOON_SCENE.instantiate()
			boon.global_position = get_global_mouse_position()
			add_child(boon)

func _on_npc_converted(npc: Node) -> void:
	if not _head_preacher_assigned:
		_head_preacher_assigned = true
		npc.assign_head_preacher()

func _on_shrine_unlocked() -> void:
	var site := SHRINE_CONSTRUCTION_SCENE.instantiate()
	site.position = Vector2(randf_range(100.0, 924.0), randf_range(100.0, 500.0))
	add_child(site)
	site.shrine_completed.connect(_on_shrine_completed.bind(site))
	EventBus.shrine_site_placed.emit(site.position)

func _on_shrine_completed(site: Node) -> void:
	var shrine := SHRINE_SCENE.instantiate()
	shrine.position = site.position
	add_child(shrine)
	GodStats.on_shrine_built()
	site.queue_free()

func _on_game_over() -> void:
	print("Game Over! All followers lost.")
