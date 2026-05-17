## Z-Fight (Era 64-bit) — sprite glitcha entre 2 frames distintos a alta velocidade,
## simulando "z-fighting" de polígonos coplanares. Movimento errático em flicker.
class_name ZFight
extends Enemy

const FLICKER_INTERVAL := 0.12

var _flicker_timer: float = 0.0
var _flicker_dir: Vector2 = Vector2.ZERO


func _init() -> void:
	max_hp = 10
	contact_damage = 12
	move_speed = 100.0
	xp_value = 2
	token_value = 2
	body_radius = 6.0
	sprite_scale = 2.0
	death_color = Color("#80deea")


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.ZFIGHT_IDLE, Sprites.PALETTE_ZFIGHT, 14.0  # frames trocam super rápido
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


## Override: movimento errático — vai direto no player mas com "flickers"
## de teleport sutil simulando z-fighting de posição.
func _chase_player(delta: float) -> void:
	if GameState.is_enemies_frozen():
		velocity = Vector2.ZERO
		return
	var player := _find_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = FLICKER_INTERVAL
		# Recalcula direção com um leve "jitter" (z-fight zigue-zague)
		var to_player := (player.global_position - global_position).normalized()
		var perp := Vector2(-to_player.y, to_player.x)
		_flicker_dir = (to_player + perp * randf_range(-0.6, 0.6)).normalized()
	velocity = _flicker_dir * move_speed
