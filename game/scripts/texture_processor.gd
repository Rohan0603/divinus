@tool
extends Node
class_name TextureProcessor

static func process_terrain_texture(input_path: String, output_path: String) -> void:
	var img: Image = (load(input_path) as Texture2D).get_image()
	img.convert(Image.FORMAT_RGBA8)

	# Desaturate to reduce visual noise
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var p := img.get_pixel(x, y)
			if p.a > 0.0:
				var gray = (p.r + p.g + p.b) / 3.0
				var desaturated = Color(gray, gray, gray, p.a)
				var blended = Color(
					lerp(p.r, desaturated.r, 0.7),
					lerp(p.g, desaturated.g, 0.7),
					lerp(p.b, desaturated.b, 0.7),
					p.a
				)
				img.set_pixel(x, y, blended)

	# Apply blur to smooth details
	var blurred = _apply_blur(img)

	# Brighten for cleaner appearance
	for x in range(blurred.get_width()):
		for y in range(blurred.get_height()):
			var p := blurred.get_pixel(x, y)
			if p.a > 0.0:
				var brightened = Color(
					clamp(p.r * 1.2, 0.0, 1.0),
					clamp(p.g * 1.2, 0.0, 1.0),
					clamp(p.b * 1.2, 0.0, 1.0),
					p.a
				)
				blurred.set_pixel(x, y, brightened)

	blurred.save_png(output_path)
	print("Terrain texture processed: ", output_path)

static func _apply_blur(img: Image) -> Image:
	var blurred = img.duplicate()
	var w = img.get_width()
	var h = img.get_height()
	var radius = 2

	for x in range(w):
		for y in range(h):
			var p = img.get_pixel(x, y)
			if p.a > 0.0:
				var r_sum = 0.0
				var g_sum = 0.0
				var b_sum = 0.0
				var a_sum = 0.0
				var count = 0

				for dx in range(-radius, radius + 1):
					for dy in range(-radius, radius + 1):
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							var neighbor = img.get_pixel(nx, ny)
							r_sum += neighbor.r
							g_sum += neighbor.g
							b_sum += neighbor.b
							a_sum += neighbor.a
							count += 1

				if count > 0:
					blurred.set_pixel(x, y, Color(
						r_sum / count,
						g_sum / count,
						b_sum / count,
						a_sum / count
					))

	return blurred
