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
const CAM_PAN_SPEED := 400.0

var _head_preacher_assigned := false
var _camera: Camera2D
var _world_gen      := WorldGenerator.new()
var _world_renderer := WorldRenderer.new()
var _land_positions: Array = []
var _cam_dragging         := false
var _cam_drag_start_mouse := Vector2.ZERO
var _cam_drag_start_pos   := Vector2.ZERO

func _ready() -> void:
	self.y_sort_enabled = true
	RenderingServer.set_default_clear_color(Color(0.18, 0.32, 0.12))
	_camera = $Camera2D
	_camera.make_current()
	EventBus.shrine_unlocked.connect(_on_shrine_unlocked)
	EventBus.npc_converted.connect(_on_npc_converted)
	EventBus.day_ending.connect(_on_day_ending)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.day_won.connect(_on_day_won)
	GodStats.game_over.connect(_on_game_over)
	_extract_clean_tiles()
	_world_gen.generate(randi())
	_populate_terrain()
	_land_positions = _world_gen.get_land_positions($TileMap)
	_spawn_vegetation()
	RivalSpawner.set_world_root(self)
	_spawn_npcs()

func _extract_clean_tiles() -> void:
	var output_path := "res://assets/tiles/medieval_fantasy_clean.png"
	if not ResourceLoader.exists(output_path):
		TileExtractor.extract_clean_tiles("res://assets/tiles/isometric_medieval_fantasy_tiles.png", output_path)

func _spawn_npcs() -> void:
	var available := _land_positions.duplicate()
	available.shuffle()
	for i in range(min(NUM_STARTING_NPCS, available.size())):
		var npc := NPC_SCENE.instantiate()
		npc.position = available[i]
		add_child(npc)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if GodStats.spend_divine_power(BOON_COST):
				var boon := BOON_SCENE.instantiate()
				boon.global_position = get_global_mouse_position()
				add_child(boon)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_cam_dragging           = true
				_cam_drag_start_mouse   = event.global_position
				_cam_drag_start_pos     = _camera.global_position
			else:
				_cam_dragging = false
	elif event is InputEventMouseMotion and _cam_dragging:
		_camera.global_position = _cam_drag_start_pos + (_cam_drag_start_mouse - event.global_position)

func _process(delta: float) -> void:
	if _cam_dragging:
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):  dir.x -= 1.0
	if Input.is_action_pressed("ui_right"): dir.x += 1.0
	if Input.is_action_pressed("ui_up"):    dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):  dir.y += 1.0
	if dir != Vector2.ZERO:
		var target_pos := _camera.position + dir.normalized() * CAM_PAN_SPEED * delta
		_smooth_camera_to(target_pos)

func _smooth_camera_to(target_pos: Vector2) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_camera, "global_position", target_pos, 0.3)

func _on_npc_converted(npc: Node) -> void:
	if not _head_preacher_assigned:
		_head_preacher_assigned = true
		npc.assign_head_preacher()

func _on_shrine_unlocked() -> void:
	var site := SHRINE_CONSTRUCTION_SCENE.instantiate()
	if _land_positions.is_empty():
		site.position = Vector2(512.0, 1280.0)
	else:
		site.position = _land_positions[randi() % _land_positions.size()]
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
	tilemap.tile_set = _world_renderer.build_tileset()
	tilemap.position = Vector2(512, 0)
	_world_renderer.render(tilemap, _world_gen)
	# Isometric 80x80 world extents (tile_size 64x32, diamond-down):
	# top=(512,0)  right=(3072,1280)  bottom=(512,2560)  left=(-2048,1280)
	_camera.limit_left   = -2100
	_camera.limit_right  =  3100
	_camera.limit_top    =  -100
	_camera.limit_bottom =  2600
	_camera.position     = Vector2(512.0, 1280.0)

func _spawn_vegetation() -> void:
	const FOREST_ASSETS: Array[String] = [
		"res://assets/nature/pine-full01.png", "res://assets/nature/pine-full02.png",
		"res://assets/nature/pine-full03.png", "res://assets/nature/pine-full04.png",
		"res://assets/nature/pine-full05.png", "res://assets/nature/bigtree01.png",
		"res://assets/nature/bigtree02.png",   "res://assets/nature/bigtree03.png",
		"res://assets/nature/bamboo01.png",    "res://assets/nature/bamboo02.png",
		"res://assets/nature/shrub1-01.png",   "res://assets/nature/shrub2-01.png",
	]
	const PLAINS_ASSETS: Array[String] = [
		"res://assets/nature/grasses01.png", "res://assets/nature/grasses02.png",
		"res://assets/nature/grasses03.png", "res://assets/nature/grasses04.png",
		"res://assets/nature/weed01.png",    "res://assets/nature/weed02.png",
		"res://assets/nature/weed03.png",    "res://assets/nature/bush01.png",
		"res://assets/nature/bush02.png",    "res://assets/nature/swirl01.png",
	]
	const SAND_ASSETS: Array[String] = [
		"res://assets/nature/cactus01.png", "res://assets/nature/cactus02.png",
		"res://assets/nature/cactus03.png", "res://assets/nature/cactus04.png",
		"res://assets/nature/bush03.png",   "res://assets/nature/bush04.png",
	]
	const MOUNTAIN_ASSETS: Array[String] = [
		"res://assets/nature/pine-none01.png", "res://assets/nature/pine-none02.png",
		"res://assets/nature/pine-none03.png", "res://assets/nature/pine-half01.png",
		"res://assets/nature/pine-half02.png",
	]

	var tilemap: TileMap = $TileMap
	for col in range(WorldGenerator.WIDTH):
		for row in range(WorldGenerator.HEIGHT):
			var biome := _world_gen.get_biome(col, row)
			var assets: Array[String]
			var density: float
			var veg_scale: float
			match biome:
				WorldGenerator.Biome.FOREST:
					assets = FOREST_ASSETS;   density = 0.12; veg_scale = 0.42
				WorldGenerator.Biome.PLAINS:
					assets = PLAINS_ASSETS;   density = 0.04; veg_scale = 0.28
				WorldGenerator.Biome.SAND:
					assets = SAND_ASSETS;     density = 0.03; veg_scale = 0.35
				WorldGenerator.Biome.MOUNTAIN:
					assets = MOUNTAIN_ASSETS; density = 0.02; veg_scale = 0.35
				_:
					continue
			if randf() > density:
				continue
			var world_pos := tilemap.to_global(tilemap.map_to_local(Vector2i(col, row)))
			world_pos += Vector2(randf_range(-14.0, 14.0), randf_range(-7.0, 7.0))
			var sp := Sprite2D.new()
			sp.texture  = load(assets[randi() % assets.size()])
			sp.scale    = Vector2.ONE * veg_scale
			sp.position = world_pos
			add_child(sp)
