## Tear — linha horizontal de tearing. Anda rápido, baixo HP.
## Movimenta-se em linha reta horizontal (não persegue verticalmente).
class_name Tear
extends Enemy


func _init() -> void:
	max_hp = 5
	contact_damage = 10
	move_speed = 110.0
	xp_value = 1
	body_radius = 6.0


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.TEAR_IDLE, Sprites.PALETTE_TEAR, 10.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _chase_player(_delta: float) -> void:
	var player := _find_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	var to := player.global_position - global_position
	var sign_x := signf(to.x)
	# Tear é horizontal-dominante mas ainda alcança verticalmente
	velocity = Vector2(sign_x * move_speed, signf(to.y) * move_speed * 0.35)
