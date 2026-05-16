## Echo — réplica corrompida do player que mimika seu movimento com delay.
## Grava o histórico de posições do player e segue posição de N segundos atrás.
class_name Echo
extends Enemy

const DELAY_SECONDS := 1.5
const RECORD_INTERVAL := 0.1


func _init() -> void:
	max_hp = 18
	contact_damage = 12
	move_speed = 0.0  # não usa pathfinding normal — segue posição gravada
	xp_value = 2
	body_radius = 6.0


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.ECHO_IDLE, Sprites.PALETTE_ECHO, 5.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


## Subclass override — usa posição gravada do player no histórico.
func _chase_player(_delta: float) -> void:
	var target_pos := PlayerTrail.get_position_seconds_ago(DELAY_SECONDS)
	if target_pos == Vector2.ZERO:
		velocity = Vector2.ZERO
		return
	var to := target_pos - global_position
	var dist := to.length()
	if dist < 1.0:
		velocity = Vector2.ZERO
		return
	# Velocidade proporcional à distância (acelera quando longe, desacelera perto)
	var speed: float = clampf(dist * 4.0, 20.0, 140.0)
	velocity = to.normalized() * speed
