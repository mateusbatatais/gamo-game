## Checksum — turret hexagonal. Não se aproxima — para em distância e dispara projétil.
class_name Checksum
extends Enemy

const PREFERRED_DISTANCE := 120.0
const DISTANCE_TOLERANCE := 20.0
const SHOOT_INTERVAL := 1.8
const PROJECTILE_DAMAGE := 11
const PROJECTILE_SPEED := 90.0

var _shoot_timer: float = 0.0


func _init() -> void:
	max_hp = 22
	contact_damage = 7
	move_speed = 30.0
	xp_value = 3
	body_radius = 7.0


func _ready() -> void:
	super()
	_shoot_timer = SHOOT_INTERVAL * 0.5 + randf() * SHOOT_INTERVAL * 0.5


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.CHECKSUM_IDLE, Sprites.PALETTE_CHECKSUM, 3.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	super(delta)
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = SHOOT_INTERVAL


## Mantém distância preferida do player (afasta se muito perto, aproxima se longe).
func _chase_player(_delta: float) -> void:
	var player := _find_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist < 1.0:
		velocity = Vector2.ZERO
		return
	var dir := to_player / dist
	if dist > PREFERRED_DISTANCE + DISTANCE_TOLERANCE:
		velocity = dir * move_speed
	elif dist < PREFERRED_DISTANCE - DISTANCE_TOLERANCE:
		velocity = -dir * move_speed
	else:
		# Strafe lateral
		var perp := Vector2(-dir.y, dir.x)
		velocity = perp * move_speed * 0.5


func _shoot() -> void:
	var player := _find_player()
	if player == null:
		return
	var dir := (player.global_position - global_position).normalized()
	var proj := EnemyProjectile.new()
	proj.setup(global_position, dir, PROJECTILE_DAMAGE, PROJECTILE_SPEED)
	get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
