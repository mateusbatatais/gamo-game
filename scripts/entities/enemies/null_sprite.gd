## Null Sprite — quadrado missing-texture. Tank: alto HP, movimento lento.
class_name NullSprite
extends Enemy


func _init() -> void:
	max_hp = 30
	contact_damage = 17
	move_speed = 36.0
	xp_value = 3
	body_radius = 8.0


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.NULL_IDLE, Sprites.PALETTE_NULL, 4.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)
