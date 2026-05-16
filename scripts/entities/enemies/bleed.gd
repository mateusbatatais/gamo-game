## Bleed — blob roxo que deixa rastro de dano residual (Stain) por onde passa.
class_name Bleed
extends Enemy

const STAIN_INTERVAL := 0.6
const STAIN_MIN_DISTANCE := 12.0

var _stain_timer: float = 0.0
var _last_stain_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	max_hp = 14
	contact_damage = 9
	move_speed = 36.0
	xp_value = 2
	body_radius = 7.0


func _ready() -> void:
	super()
	_last_stain_pos = global_position


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.BLEED_IDLE, Sprites.PALETTE_BLEED, 4.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	super(delta)
	_stain_timer -= delta
	if _stain_timer <= 0.0:
		_drop_stain_if_moved()


func _drop_stain_if_moved() -> void:
	if global_position.distance_to(_last_stain_pos) < STAIN_MIN_DISTANCE:
		return
	_stain_timer = STAIN_INTERVAL
	_last_stain_pos = global_position
	var stain := Stain.new()
	stain.global_position = global_position
	get_parent().add_child(stain)
