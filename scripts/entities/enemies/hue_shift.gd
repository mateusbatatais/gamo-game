## HueShift — inimigo 16-bit que cicla por matizes a cada 0.4s.
## Visualmente forma uma "discoteca" pixelada. Movimento ondulado leve.
class_name HueShift
extends Enemy

const HUE_CYCLE_INTERVAL := 0.4
const HUE_COLORS: Array[Color] = [
	Color("#00bcd4"),  # cyan
	Color("#e040fb"),  # magenta
	Color("#ffeb3b"),  # yellow
	Color("#ff5722"),  # red-orange
	Color("#76ff03"),  # green
]

var _hue_index: int = 0
var _hue_timer: float = 0.0


func _init() -> void:
	max_hp = 12
	contact_damage = 9
	move_speed = 42.0
	xp_value = 2
	body_radius = 6.0


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.add_frame("default", PixelArt.make_sprite(
		PackedStringArray(Sprites.HUE_SHIFT_IDLE[0]),
		Sprites.PALETTE_HUE_SHIFT
	))
	sprite.sprite_frames = sf
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	sprite.modulate = HUE_COLORS[0]
	add_child(sprite)


func _physics_process(delta: float) -> void:
	super(delta)
	_hue_timer -= delta
	if _hue_timer <= 0.0:
		_hue_timer = HUE_CYCLE_INTERVAL
		_hue_index = (_hue_index + 1) % HUE_COLORS.size()
		if sprite != null and _flash_timer <= 0.0:
			sprite.modulate = HUE_COLORS[_hue_index]


func _update_flash(delta: float) -> void:
	# Override pra preservar modulate cyclando após hit
	if sprite == null:
		return
	if _flash_timer > 0.0:
		_flash_timer -= delta
		sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
	else:
		sprite.modulate = HUE_COLORS[_hue_index]
