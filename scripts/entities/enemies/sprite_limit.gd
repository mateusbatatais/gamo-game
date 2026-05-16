## Sprite Limit — quando toma dano e ainda tem HP, tem chance de se dividir.
## Filhos são versões menores (50% HP, 70% scale, 70% damage).
class_name SpriteLimit
extends Enemy

const SPLIT_CHANCE := 0.4
const MIN_HP_TO_SPLIT := 4

@export var split_generation: int = 0
const MAX_GENERATIONS := 2


func _init() -> void:
	max_hp = 20
	contact_damage = 10
	move_speed = 38.0
	xp_value = 3
	body_radius = 7.0


func _ready() -> void:
	super()
	# Aplica redução de stats se for spawn de divisão
	if split_generation > 0:
		var mult: float = pow(0.7, split_generation)
		sprite_scale = max(1.4, sprite_scale * mult)
		body_radius = max(4.0, body_radius * mult)
		contact_damage = max(2, int(contact_damage * mult))
		if sprite != null:
			sprite.scale = Vector2(sprite_scale, sprite_scale)


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.add_frame("default", PixelArt.make_sprite(
		PackedStringArray(Sprites.SPRITE_LIMIT_IDLE[0]),
		Sprites.PALETTE_SPRITE_LIMIT
	))
	sprite.sprite_frames = sf
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO, is_crit: bool = false) -> void:
	super(amount, knockback_dir, is_crit)
	if current_hp > 0 and current_hp >= MIN_HP_TO_SPLIT and split_generation < MAX_GENERATIONS:
		if randf() < SPLIT_CHANCE:
			_try_split()


func _try_split() -> void:
	var clone := SpriteLimit.new()
	clone.split_generation = split_generation + 1
	var angle: float = randf() * TAU
	clone.global_position = global_position + Vector2(cos(angle), sin(angle)) * 12.0
	get_parent().add_child(clone)
