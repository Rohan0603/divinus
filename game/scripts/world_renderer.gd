# game/scripts/world_renderer.gd
class_name WorldRenderer

const _TINTS := {
	WorldGenerator.Biome.WATER:    Color(0.20, 0.45, 0.85),
	WorldGenerator.Biome.SAND:     Color(0.87, 0.78, 0.52),
	WorldGenerator.Biome.PLAINS:   Color(0.52, 0.78, 0.32),
	WorldGenerator.Biome.FOREST:   Color(0.28, 0.55, 0.18),
	WorldGenerator.Biome.MOUNTAIN: Color(0.65, 0.65, 0.65),
}
const _BASE_TEXTURE := {
	WorldGenerator.Biome.WATER:    "res://assets/tiles/grass_block_S.png",
	WorldGenerator.Biome.SAND:     "res://assets/tiles/grass_block_S.png",
	WorldGenerator.Biome.PLAINS:   "res://assets/tiles/grass_block_S.png",
	WorldGenerator.Biome.FOREST:   "res://assets/tiles/grass_block_S.png",
	WorldGenerator.Biome.MOUNTAIN: "res://assets/tiles/cliff_top_S.png",
}

func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size        = Vector2i(64, 32)
	ts.tile_shape       = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout      = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	for biome in _TINTS.keys():
		ts.add_source(_make_source(_BASE_TEXTURE[biome], _TINTS[biome]), biome)
	return ts

func _make_source(path: String, tint: Color) -> TileSetAtlasSource:
	var img: Image = (load(path) as Texture2D).get_image()
	img.resize(64, 128, Image.INTERPOLATE_BILINEAR)
	img.convert(Image.FORMAT_RGBA8)
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var p := img.get_pixel(x, y)
			if p.a > 0.0:
				img.set_pixel(x, y, Color(p.r * tint.r, p.g * tint.g, p.b * tint.b, p.a))
	var src := TileSetAtlasSource.new()
	src.texture             = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(64, 128)
	src.create_tile(Vector2i(0, 0))
	return src

func render(tilemap: TileMap, generator: WorldGenerator) -> void:
	tilemap.clear()
	if tilemap.get_layers_count() == 0:
		tilemap.add_layer(0)
	tilemap.set_layer_y_sort_enabled(0, true)
	for col in range(WorldGenerator.WIDTH):
		for row in range(WorldGenerator.HEIGHT):
			var biome := generator.get_biome(col, row)
			tilemap.set_cell(0, Vector2i(col, row), biome, Vector2i(0, 0))
