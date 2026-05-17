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
	self.y_sort_enabled = true
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.08))
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
		npc.position = Vector2(randf_range(220.0, 820.0), randf_range(160.0, 450.0))
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
	site.position = Vector2(randf_range(220.0, 820.0), randf_range(160.0, 450.0))
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

# Populate tilemap with isometric kenney terrain
func _populate_terrain() -> void:
	var tilemap: TileMap = $TileMap
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(64, 32)
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL

	# Scale kenney tiles from 256x512 to 64x128 at runtime
	# Diamond face = top 64x32; 3D depth = remaining 64x96
	var paths := [
		"res://resources/tiles/kenney_dirt.png",
		"res://resources/tiles/kenney_dirtTiles.png",
		"res://resources/tiles/kenney_stone.png",
	]
	for idx in paths.size():
		var img: Image = (load(paths[idx]) as Texture2D).get_image()
		img.resize(64, 128, Image.INTERPOLATE_BILINEAR)
		var tex := ImageTexture.create_from_image(img)
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(64, 128)
		src.create_tile(Vector2i(0, 0))
		tileset.add_source(src, idx)

	tilemap.tile_set = tileset

	if tilemap.get_layers_count() == 0:
		tilemap.add_layer(0)
	tilemap.set_layer_y_sort_enabled(0, true)

	# Center isometric diamond on 1024x600 viewport
	# tile(i,j) → world(512+(i-j)*32, (i+j)*16)
	tilemap.position = Vector2(512, 0)

	for i in range(34):
		for j in range(38):
			var rng := randf()
			var source_id: int
			if rng < 0.10:
				source_id = 2  # stone accent
			elif rng < 0.30:
				source_id = 0  # plain dirt (sandy patches)
			else:
				source_id = 1  # dirtTiles (main tiled floor)
			tilemap.set_cell(0, Vector2i(i, j), source_id, Vector2i(0, 0))
