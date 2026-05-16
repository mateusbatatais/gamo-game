## Procedural pixel sprite generator.
## Converte arrays de strings (ASCII art) em ImageTextures usando uma paleta.
## Usage:
##   var tex := PixelArt.make_sprite(PIXEL_FRAMES, PIXEL_PALETTE)
##
## Convenção de chars:
##   - "." e " " = transparente
##   - qualquer outro char = chave da paleta
class_name PixelArt
extends RefCounted


## Gera uma ImageTexture a partir de um frame (PackedStringArray) e paleta.
static func make_sprite(frame: PackedStringArray, palette: Dictionary) -> ImageTexture:
	var image := _frame_to_image(frame, palette)
	return ImageTexture.create_from_image(image)


## Gera um SpriteFrames (para AnimatedSprite2D) a partir de múltiplos frames.
static func make_animation(frames: Array, palette: Dictionary, fps: float = 6.0) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_speed("default", fps)
	sf.set_animation_loop("default", true)
	for frame_data in frames:
		var packed: PackedStringArray
		if frame_data is PackedStringArray:
			packed = frame_data
		else:
			packed = PackedStringArray(frame_data)
		var image := _frame_to_image(packed, palette)
		sf.add_frame("default", ImageTexture.create_from_image(image))
	return sf


## Cria um quadrado colorido sólido como ImageTexture.
static func solid_square(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


## Cria um círculo aproximado em pixel art.
static func solid_circle(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var radius := float(size) / 2.0
	var center := Vector2(radius - 0.5, radius - 0.5)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center)
			if d <= radius - 0.5:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


static func _frame_to_image(frame: PackedStringArray, palette: Dictionary) -> Image:
	assert(frame.size() > 0, "Frame vazio")
	var height := frame.size()
	var width := frame[0].length()
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in height:
		var row := frame[y]
		for x in row.length():
			var ch := row[x]
			if ch == " " or ch == ".":
				continue
			var color: Color = palette.get(ch, Color.MAGENTA)
			img.set_pixel(x, y, color)
	return img
