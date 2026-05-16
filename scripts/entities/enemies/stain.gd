## Stain — pegada de dano residual deixada pelo Bleed.
## Estende Enemy para que o player.hurtbox detecte e cause dano de contato.
## Imortal e estacionária — some por tempo de vida.
class_name Stain
extends Enemy

const LIFETIME := 3.0

var _age: float = 0.0


func _init() -> void:
	max_hp = 9999
	contact_damage = 6
	move_speed = 0.0
	xp_value = 0
	body_radius = 8.0
	sprite_scale = 2.0


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.add_frame("default", Sprites.stain)
	sprite.sprite_frames = sf
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _chase_player(_delta: float) -> void:
	velocity = Vector2.ZERO


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	if sprite != null:
		sprite.modulate.a = 1.0 - (_age / LIFETIME)


func take_damage(_amount: int, _knockback_dir: Vector2 = Vector2.ZERO, _is_crit: bool = false) -> void:
	# Imortal — não toma dano
	pass


func _die() -> void:
	# Some sem deixar XP gem
	queue_free()
