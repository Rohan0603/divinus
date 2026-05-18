# game/scripts/world_renderer.gd
class_name WorldRenderer

const _TILE_PATHS: Dictionary = {
	WorldGenerator.Biome.WATER:    "res://assets/tiles/tiles_water.png",
	WorldGenerator.Biome.SAND:     "res://assets/tiles/tiles_sand.png",
	WorldGenerator.Biome.PLAINS:   "res://assets/tiles/tiles_plains.png",
	WorldGenerator.Biome.FOREST:   "res://assets/tiles/tiles_forest.png",
	WorldGenerator.Biome.MOUNTAIN: "res://assets/tiles/tiles_mountain.png",
}

func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	ts.tile_size = Vector2i(64, 32)
	for biome in _TILE_PATHS:
		var src := _make_source(_TILE_PATHS[biome])
		ts.add_source(src, biome * 10)
	return ts

func _make_source(path: String) -> TileSetAtlasSource:
	var fallback := "res://assets/tiles/isometric_medieval_fantasy_tiles.png"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else load(fallback)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(64, 32)
	for r in range(5):
		for c in range(2):
			src.create_tile(Vector2i(c, r))
	return src

func render(tilemap: TileMap, generator: WorldGenerator) -> void:
	tilemap.clear()
	if tilemap.get_layers_count() == 0:
		tilemap.add_layer(0)
	tilemap.set_layer_y_sort_enabled(0, true)
	for col in range(WorldGenerator.WIDTH):
		for row in range(WorldGenerator.HEIGHT):
			var biome := generator.get_biome(col, row)
			# Randomly pick a tile variant from the spritesheet (2 cols × 5 rows)
			var tile_x := randi() % 2
			var tile_y := randi() % 5
			tilemap.set_cell(0, Vector2i(col, row), biome * 10, Vector2i(tile_x, tile_y))
