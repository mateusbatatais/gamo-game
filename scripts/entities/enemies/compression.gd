## Compression — bloco JPG-style que teleporta perto do player a cada N segundos.
## Não tem perseguição normal — fica parado entre teleports.
class_name Compression
extends Enemy

const TELEPORT_INTERVAL := 2.5
const TELEPORT_RANGE_MIN := 60.0
const TELEPORT_RANGE_MAX := 100.0

var _teleport_timer: float = 0.0


func _init() -> void:
	max_hp = 16
	contact_damage = 14
	move_speed = 0.0
	xp_value = 3
	body_radius = 7.0


func _ready() -> void:
	super()
	_teleport_timer = TELEPORT_INTERVAL * (0.5 + randf() * 0.5)


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.COMPRESSION_IDLE, Sprites.PALETTE_COMPRESSION, 3.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _chase_player(_delta: float) -> void:
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	super(delta)
	_teleport_timer -= delta
	if _teleport_timer <= 0.0:
		_teleport_timer = TELEPORT_INTERVAL
		_teleport()


func _teleport() -> void:
	var player := _find_player()
	if player == null:
		return
	var angle: float = randf() * TAU
	var distance: float = randf_range(TELEPORT_RANGE_MIN, TELEPORT_RANGE_MAX)
	var new_pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	var rect: Rect2 = ArenaBounds.get_rect()
	new_pos.x = clampf(new_pos.x, rect.position.x + 16, rect.end.x - 16)
	new_pos.y = clampf(new_pos.y, rect.position.y + 16, rect.end.y - 16)
	global_position = new_pos
	# Flash branco rápido pra indicar teleport
	if sprite != null:
		sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	_flash_timer = 0.15
