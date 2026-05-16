## Bit Flip — alterna entre 2 estados a cada 1.5s.
## Estado ON: vulneravel, dispara mais rapido. Estado OFF: invulneravel, anda lento.
class_name BitFlip
extends Enemy

const FLIP_INTERVAL := 1.5

var _state_on: bool = true
var _flip_timer: float = 0.0
var _texture_on: ImageTexture
var _texture_off: ImageTexture


func _init() -> void:
	max_hp = 24
	contact_damage = 12
	move_speed = 50.0
	xp_value = 3
	body_radius = 6.0


func _ready() -> void:
	super()
	_flip_timer = FLIP_INTERVAL + randf() * 0.5


func _build_visual() -> void:
	_texture_on = PixelArt.make_sprite(
		PackedStringArray(Sprites.BIT_FLIP_IDLE[0]),
		Sprites.PALETTE_BIT_FLIP_ON
	)
	_texture_off = PixelArt.make_sprite(
		PackedStringArray(Sprites.BIT_FLIP_IDLE[1]),
		Sprites.PALETTE_BIT_FLIP_OFF
	)
	sprite = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.add_frame("default", _texture_on)
	sprite.sprite_frames = sf
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	super(delta)
	_flip_timer -= delta
	if _flip_timer <= 0.0:
		_flip_timer = FLIP_INTERVAL
		_toggle_state()


func _toggle_state() -> void:
	_state_on = not _state_on
	if sprite == null:
		return
	var sf: SpriteFrames = sprite.sprite_frames
	sf.set_frame("default", 0, _texture_on if _state_on else _texture_off)


## Move 2x mais rápido quando OFF (compensa invulnerabilidade).
func _chase_player(_delta: float) -> void:
	var player := _find_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	var dir := player.global_position - global_position
	if dir.length_squared() < 0.01:
		velocity = Vector2.ZERO
		return
	var speed_mult: float = 1.6 if not _state_on else 1.0
	velocity = dir.normalized() * move_speed * speed_mult


## Recebe dano apenas no estado ON.
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO, is_crit: bool = false) -> void:
	if not _state_on:
		# Visual feedback de "imune"
		_flash_timer = 0.05
		return
	super(amount, knockback_dir, is_crit)
