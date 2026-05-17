# main.gd — Root game script
extends Node2D

const NPC_SCENE := preload("res://scenes/NPC.tscn")
const SHRINE_CONSTRUCTION_SCENE := preload("res://scenes/ShrineConstructionSite.tscn")
const SHRINE_SCENE := preload("res://scenes/Shrine.tscn")
const BOON_SCENE := preload("res://scenes/Boon.tscn")
const WIN_SCREEN_SCENE := preload("res://scenes/WinScreen.tscn")

const NUM_STARTING_NPCS := 6
const BOON_COST := 5.0
const SCREEN_SHAKE_INTENSITY := 4.0
const SCREEN_SHAKE_DURATION := 0.3

var _head_preacher_assigned := false
var _camera: Camera2D

func _ready() -> void:
	_camera = $Camera2D
	_camera.make_current()
	EventBus.shrine_unlocked.connect(_on_shrine_unlocked)
	EventBus.npc_converted.connect(_on_npc_converted)
	EventBus.day_ending.connect(_on_day_ending)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.day_won.connect(_on_day_won)
	GodStats.game_over.connect(_on_game_over)
	_populate_terrain()
	RivalSpawner.set_world_root(self)
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

func _on_day_won() -> void:
	var win_screen := WIN_SCREEN_SCENE.instantiate()
	add_child(win_screen)

func _on_day_ending(_day_number: int) -> void:
	# Screen shake when raid begins
	_screen_shake()

func _on_enemy_spawned(_position: Vector2) -> void:
	# Optional: mini shake on each enemy spawn (can be intense, so just on day_ending for now)
	pass

# Screen shake effect using camera
func _screen_shake() -> void:
	var orig_offset = _camera.offset
	var elapsed = 0.0

	while elapsed < SCREEN_SHAKE_DURATION:
		_camera.offset = orig_offset + Vector2(
			randf_range(-SCREEN_SHAKE_INTENSITY, SCREEN_SHAKE_INTENSITY),
			randf_range(-SCREEN_SHAKE_INTENSITY, SCREEN_SHAKE_INTENSITY)
		)
		elapsed += get_physics_process_delta_time()
		await get_tree().process_frame

	_camera.offset = orig_offset

# Populate tilemap with simple grass terrain
func _populate_terrain() -> void:
	var tilemap: TileMap = $TileMap
	print("[DEBUG] TileMap node: ", tilemap)
	print("[DEBUG] TileMap visible: ", tilemap.visible)

	# Create TileSet programmatically instead of loading from .tres
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(32, 32)

	# Load the texture
	var grass_texture = load("res://resources/grass.png")
	print("[DEBUG] Grass texture loaded: ", grass_texture)

	if grass_texture == null:
		push_error("Failed to load grass.png")
		return

	# Create TileSetAtlasSource for grass tiles
	var grass_source = TileSetAtlasSource.new()
	grass_source.texture = grass_texture
	grass_source.texture_region_size = Vector2i(32, 32)
	grass_source.create_tile(Vector2i(0, 0))

	# Create TileSetAtlasSource for dirt tiles
	var dirt_source = TileSetAtlasSource.new()
	dirt_source.texture = grass_texture
	dirt_source.texture_region_size = Vector2i(32, 32)
	dirt_source.create_tile(Vector2i(0, 0))

	# Add sources to tileset
	tileset.add_source(grass_source, 0)
	tileset.add_source(dirt_source, 1)

	print("[DEBUG] TileSet created programmatically with ", tileset.get_source_count(), " sources")
	tilemap.tile_set = tileset

	var tile_size = 32
	var grid_width = 1024 / tile_size
	var grid_height = 600 / tile_size

	print("[DEBUG] Grid: ", grid_width, "x", grid_height)
	print("[DEBUG] Populating terrain...")

	var cell_count = 0
	for x in range(grid_width):
		for y in range(grid_height):
			# Grass tile (ID 0) for all positions; occasional dirt (ID 1)
			var source_id = 1 if randf() < 0.15 else 0
			tilemap.set_cell(0, Vector2i(x, y), source_id, Vector2i(0, 0))
			cell_count += 1

	print("[DEBUG] Terrain populated: ", cell_count, " cells")
