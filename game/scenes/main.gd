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
	RenderingServer.set_default_clear_color(Color(0.18, 0.32, 0.12))
	_camera = $Camera2D
	_camera.make_current()
	EventBus.shrine_unlocked.connect(_on_shrine_unlocked)
	EventBus.npc_converted.connect(_on_npc_converted)
	EventBus.day_ending.connect(_on_day_ending)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.day_won.connect(_on_day_won)
	GodStats.game_over.connect(_on_game_over)
	_populate_terrain()
	_spawn_vegetation()
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
	var img: Image = (load("res://assets/tiles/dirtTiles_S.png") as Texture2D).get_image()
	img.resize(64, 128, Image.INTERPOLATE_BILINEAR)
	var tex := ImageTexture.create_from_image(img)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(64, 128)
	src.create_tile(Vector2i(0, 0))
	tileset.add_source(src, 0)

	tilemap.tile_set = tileset

	if tilemap.get_layers_count() == 0:
		tilemap.add_layer(0)
	tilemap.set_layer_y_sort_enabled(0, true)

	tilemap.position = Vector2(512, 0)

	for i in range(34):
		for j in range(38):
			tilemap.set_cell(0, Vector2i(i, j), 0, Vector2i(0, 0))

func _spawn_vegetation() -> void:
	const LARGE_TREES := [
		"res://assets/nature/pine-full01.png", "res://assets/nature/pine-full02.png",
		"res://assets/nature/pine-full03.png", "res://assets/nature/pine-full04.png",
		"res://assets/nature/pine-full05.png", "res://assets/nature/pine-full06.png",
		"res://assets/nature/pine-full07.png", "res://assets/nature/pine-full08.png",
		"res://assets/nature/bigtree01.png", "res://assets/nature/bigtree02.png",
		"res://assets/nature/bigtree03.png",
	]
	const MEDIUM_PLANTS := [
		"res://assets/nature/palm01.png", "res://assets/nature/palm02.png",
		"res://assets/nature/palm03.png", "res://assets/nature/palm04.png",
		"res://assets/nature/palm05.png", "res://assets/nature/palm06.png",
		"res://assets/nature/shrub1-01.png", "res://assets/nature/shrub1-02.png",
		"res://assets/nature/shrub1-03.png", "res://assets/nature/shrub1-04.png",
		"res://assets/nature/shrub1-05.png",
		"res://assets/nature/shrub2-01.png", "res://assets/nature/shrub2-02.png",
		"res://assets/nature/shrub2-03.png", "res://assets/nature/shrub2-04.png",
		"res://assets/nature/shrub2-05.png",
		"res://assets/nature/bamboo01.png", "res://assets/nature/bamboo02.png",
		"res://assets/nature/bamboo03.png", "res://assets/nature/bamboo04.png",
		"res://assets/nature/bamboo05.png", "res://assets/nature/bamboo06.png",
		"res://assets/nature/hemp01.png", "res://assets/nature/hemp02.png",
		"res://assets/nature/hemp03.png",
		"res://assets/nature/tropical01.png", "res://assets/nature/tropical02.png",
		"res://assets/nature/tropical03.png", "res://assets/nature/tropical04.png",
		"res://assets/nature/tropical05.png",
		"res://assets/nature/pine-half01.png", "res://assets/nature/pine-half02.png",
		"res://assets/nature/pine-half03.png", "res://assets/nature/pine-half04.png",
	]
	const GROUND_COVER := [
		"res://assets/nature/grasses01.png", "res://assets/nature/grasses02.png",
		"res://assets/nature/grasses03.png", "res://assets/nature/grasses04.png",
		"res://assets/nature/grasses05.png",
		"res://assets/nature/weed01.png", "res://assets/nature/weed02.png",
		"res://assets/nature/weed03.png", "res://assets/nature/weed04.png",
		"res://assets/nature/weed05.png", "res://assets/nature/weed06.png",
		"res://assets/nature/swirl01.png", "res://assets/nature/swirl02.png",
		"res://assets/nature/bush01.png", "res://assets/nature/bush02.png",
		"res://assets/nature/bush03.png", "res://assets/nature/bush04.png",
		"res://assets/nature/bush05.png",
		"res://assets/nature/cactus01.png", "res://assets/nature/cactus02.png",
		"res://assets/nature/cactus03.png", "res://assets/nature/cactus04.png",
		"res://assets/nature/pine-none01.png", "res://assets/nature/pine-none02.png",
		"res://assets/nature/pine-none03.png", "res://assets/nature/pine-none04.png",
	]
	var placed: Array = []
	_spawn_plant_layer(LARGE_TREES,   10, Vector2(0.45, 0.45), 140.0, placed)
	_spawn_plant_layer(MEDIUM_PLANTS, 35, Vector2(0.35, 0.35),  70.0, placed)
	_spawn_plant_layer(GROUND_COVER,  50, Vector2(0.28, 0.28),  35.0, placed)


func _spawn_plant_layer(textures: Array, count: int, prop_scale: Vector2, min_dist: float, placed: Array) -> void:
	for _i in range(count):
		var tex_path: String = textures[randi() % textures.size()]
		var tex := load(tex_path) as Texture2D
		if tex == null:
			continue
		var pos := Vector2.ZERO
		var attempts := 0
		while attempts < 25:
			pos = Vector2(randf_range(220.0, 820.0), randf_range(140.0, 490.0))
			var too_close := false
			for p in placed:
				if pos.distance_to(p) < min_dist:
					too_close = true
					break
			if not too_close:
				break
			attempts += 1
		if attempts >= 25:
			continue
		placed.append(pos)
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.scale = prop_scale
		sprite.position = pos
		add_child(sprite)
