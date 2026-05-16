## ASCII Swarm — caractere voador rápido e frágil. Aparece em enxames.
## Movimento errático: persegue o player com pequenas oscilações.
class_name AsciiSwarm
extends Enemy

const WOBBLE_AMPLITUDE := 40.0
const WOBBLE_FREQUENCY := 4.0

var _wobble_phase: float = 0.0


func _init() -> void:
	max_hp = 3
	contact_damage = 5
	move_speed = 80.0
	xp_value = 1
	body_radius = 4.0


func _ready() -> void:
	super()
	_wobble_phase = randf() * TAU


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.SWARM_IDLE, Sprites.PALETTE_SWARM, 12.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _chase_player(delta: float) -> void:
	var player := _find_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	_wobble_phase += delta * WOBBLE_FREQUENCY
	var dir := (player.global_position - global_position)
	if dir.length_squared() < 0.01:
		velocity = Vector2.ZERO
		return
	var base := dir.normalized()
	var perp := Vector2(-base.y, base.x)
	velocity = base * move_speed + perp * sin(_wobble_phase) * WOBBLE_AMPLITUDE
