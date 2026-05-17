## FMV (Era 32-bit CD) — bloco de vídeo full-motion corrompido. Para periodicamente
## "buffer" e dispara um pulso quadrado em 4 direções cardeais.
class_name Fmv
extends Enemy

const BUFFER_INTERVAL := 3.5
const BUFFER_DURATION := 0.8
const PROJECTILE_DAMAGE := 8
const PROJECTILE_SPEED := 100.0

var _buffer_timer: float = 0.0
var _buffer_remaining: float = 0.0


func _init() -> void:
	max_hp = 26
	contact_damage = 10
	move_speed = 38.0
	xp_value = 3
	token_value = 3
	body_radius = 7.0
	sprite_scale = 2.0
	death_color = Color("#ff6f00")


func _ready() -> void:
	super()
	_buffer_timer = BUFFER_INTERVAL * (0.4 + randf() * 0.6)


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.FMV_IDLE, Sprites.PALETTE_FMV, 4.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	_buffer_timer -= delta
	if _buffer_timer <= 0.0:
		_buffer_timer = BUFFER_INTERVAL
		_buffer_remaining = BUFFER_DURATION
		_fire_cardinal_burst()
	# Quando bufferando, fica parado tremendo levemente.
	if _buffer_remaining > 0.0:
		_buffer_remaining -= delta
		velocity = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		_update_flash(delta)
		move_and_slide()
		return
	super(delta)


func _fire_cardinal_burst() -> void:
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, PROJECTILE_DAMAGE, PROJECTILE_SPEED)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
