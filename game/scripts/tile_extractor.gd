@tool
extends Node
class_name TileExtractor

static func extract_clean_tiles(source_path: String, output_path: String) -> void:
	var img: Image = (load(source_path) as Texture2D).get_image()
	if img == null:
		print("ERROR: Could not load source texture: ", source_path)
		return

	img.convert(Image.FORMAT_RGBA8)

	# Extract top 3 rows of cleanest tiles (simple grass, dirt, stone variants)
	# Assumes ~64x64 pixel tiles arranged in a grid
	var tile_size = 64
	var rows_to_extract = 3
	var cols_to_extract = 8

	var extracted_width = cols_to_extract * tile_size
	var extracted_height = rows_to_extract * tile_size

	var extracted = Image.create(extracted_width, extracted_height, false, Image.FORMAT_RGBA8)

	for y in range(extracted_height):
		for x in range(extracted_width):
			if y < img.get_height() and x < img.get_width():
				extracted.set_pixel(x, y, img.get_pixel(x, y))

	extracted.save_png(output_path)
	print("Clean tiles extracted: ", output_path)
