## Wireframe Hulk (Era 64-bit) — tank pseudo-3D com muito HP e dano de contato.
## Move-se lentamente direto no player. Resistente a single-hits, vulnerável a piercing/area.
class_name WireframeHulk
extends Enemy


func _init() -> void:
	max_hp = 55
	contact_damage = 16
	move_speed = 26.0
	xp_value = 5
	token_value = 4
	body_radius = 9.0
	sprite_scale = 2.0
	death_color = Color("#90a4ae")


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.WIREFRAME_IDLE, Sprites.PALETTE_WIREFRAME, 2.5
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)
