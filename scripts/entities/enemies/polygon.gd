## Polygon (Era 32-bit CD) — triângulo pseudo-3D que persegue o player em
## ângulo enquanto rotaciona. Frágil mas rápido.
class_name Polygon
extends Enemy


func _init() -> void:
	max_hp = 12
	contact_damage = 10
	move_speed = 90.0
	xp_value = 2
	token_value = 2
	body_radius = 6.0
	sprite_scale = 2.0
	death_color = Color("#00e5ff")


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.POLYGON_IDLE, Sprites.PALETTE_POLYGON, 8.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	super(delta)
	# Rotação visual constante (não afeta colisão)
	if sprite != null:
		sprite.rotation += delta * 4.0
