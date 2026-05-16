## Memory Leak — bloco corrompido que cresce com o tempo.
## Quase parado, mas vai aumentando de tamanho/dano. Ao morrer, libera 3 ASCII Swarm.
class_name MemoryLeak
extends Enemy

const GROWTH_RATE := 0.04  # scale por segundo
const MAX_SCALE_MULT := 2.5
const SWARM_RELEASE_COUNT := 3

var _growth: float = 0.0


func _init() -> void:
	max_hp = 35
	contact_damage = 10
	move_speed = 12.0
	xp_value = 4
	body_radius = 7.0


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.LEAK_IDLE, Sprites.PALETTE_LEAK, 2.5
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	super(delta)
	_growth = min(_growth + GROWTH_RATE * delta, MAX_SCALE_MULT - 1.0)
	var s: float = sprite_scale * (1.0 + _growth)
	if sprite != null:
		sprite.scale = Vector2(s, s)
	# Hitbox cresce também
	var col := get_child(0)
	if col is CollisionShape2D:
		var shape := (col as CollisionShape2D).shape
		if shape is CircleShape2D:
			(shape as CircleShape2D).radius = body_radius * (1.0 + _growth)


func _die() -> void:
	Audio.play(Audio.Sfx.ENEMY_DIE)
	GameState.register_kill()
	EventBus.enemy_killed.emit(self, xp_value)
	_drop_xp_gem()
	_release_swarm()
	queue_free()


func _release_swarm() -> void:
	for i in SWARM_RELEASE_COUNT:
		var swarm := AsciiSwarm.new()
		var angle: float = TAU * float(i) / float(SWARM_RELEASE_COUNT)
		swarm.global_position = global_position + Vector2(cos(angle), sin(angle)) * 16.0
		get_parent().add_child(swarm)
