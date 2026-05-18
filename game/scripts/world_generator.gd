# game/scripts/world_generator.gd
class_name WorldGenerator

const WIDTH  := 80
const HEIGHT := 80

enum Biome { WATER = 0, SAND = 1, PLAINS = 2, FOREST = 3, MOUNTAIN = 4 }

var biome_map: Array[Array[int]] = []

func generate(gen_seed: int) -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type         = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed               = gen_seed
	noise.frequency          = 0.035
	noise.fractal_octaves    = 4
	noise.fractal_gain       = 0.5
	noise.fractal_lacunarity = 2.0

	biome_map.clear()
	for col in range(WIDTH):
		var row_arr := []
		for row in range(HEIGHT):
			var elev := noise.get_noise_2d(float(col), float(row))
			row_arr.append(_to_biome(elev))
		biome_map.append(row_arr)

func _to_biome(elev: float) -> int:
	if elev < -0.3:  return Biome.WATER
	if elev < -0.1:  return Biome.SAND
	if elev <  0.2:  return Biome.PLAINS
	if elev <  0.45: return Biome.FOREST
	return Biome.MOUNTAIN

func get_biome(col: int, row: int) -> int:
	return biome_map[col][row]

# Returns world-space positions of all non-water, non-mountain tiles.
# Call AFTER tilemap.position is set (i.e. after _populate_terrain).
func get_land_positions(tilemap: TileMap) -> Array:
	var positions: Array = []
	for col in range(WIDTH):
		for row in range(HEIGHT):
			var b := biome_map[col][row]
			if b != Biome.WATER and b != Biome.MOUNTAIN:
				positions.append(tilemap.to_global(tilemap.map_to_local(Vector2i(col, row))))
	return positions
