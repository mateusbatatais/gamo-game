## Artifact — pixel verde piscando. Movimento lento direto no jogador.
class_name Artifact
extends Enemy


func _init() -> void:
	max_hp = 8
	contact_damage = 7
	move_speed = 48.0
	xp_value = 1
	body_radius = 6.0


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.ARTIFACT_IDLE, Sprites.PALETTE_ARTIFACT, 5.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)
