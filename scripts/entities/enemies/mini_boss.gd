## Mini-boss "Sentinel" — picos de tensão aos 2:00 e 4:00 da run.
## HP alto, dano de contato forte, dispara ring de projéteis em intervalos.
## Drop garantido de health + power-up aleatório ao morrer.
class_name MiniBoss
extends Enemy

const RING_INTERVAL := 3.5
const RING_PROJECTILES := 10
const RING_SPEED := 130.0
const RING_DAMAGE := 10  # era 6
const POWERUP_BIAS := [PowerUp.Kind.NUKE, PowerUp.Kind.MAGNET, PowerUp.Kind.FREEZE]

var _ring_timer: float = 1.5


func _init() -> void:
	max_hp = 240
	contact_damage = 24  # era 14
	move_speed = 40.0
	xp_value = 25
	token_value = 20  # mini-bosses dão bom bônus de tokens
	body_radius = 14.0
	sprite_scale = 2.4
	death_color = Color("#e040fb")
	health_drop_chance = 1.0


func _ready() -> void:
	super()
	add_to_group("boss")  # já é Enemy, mas marcar como "boss" pra não ser limpo no spawn do boss final


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_speed("default", 2.2)
	sf.set_animation_loop("default", true)
	for tex in Sprites.miniboss_idle:
		sf.add_frame("default", tex)
	sprite.sprite_frames = sf
	sprite.play("default")
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	add_child(sprite)


func _physics_process(delta: float) -> void:
	super(delta)
	if GameState.run_active and not is_queued_for_deletion():
		_ring_timer -= delta
		if _ring_timer <= 0.0:
			_ring_timer = RING_INTERVAL
			_fire_ring()


func _fire_ring() -> void:
	for i in RING_PROJECTILES:
		var angle: float = TAU * float(i) / float(RING_PROJECTILES)
		var dir := Vector2(cos(angle), sin(angle))
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, RING_DAMAGE, RING_SPEED)
		get_parent().add_child(proj)


func _die() -> void:
	Audio.play(Audio.Sfx.ENEMY_DIE)
	Audio.play(Audio.Sfx.LEVEL_UP)
	HitStop.freeze_big()
	GameState.register_kill()
	GameState.grant_tokens(token_value)
	EventBus.enemy_killed.emit(self, xp_value)

	# Explosão maior
	for j in 3:
		var burst := DeathParticle.new()
		burst.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		burst.setup(death_color)
		get_parent().add_child(burst)

	# Fountain de XP
	for i in 6:
		var gem := XpGem.new()
		gem.value = 4
		var angle: float = TAU * float(i) / 6.0
		gem.global_position = global_position + Vector2(cos(angle), sin(angle)) * 16.0
		get_parent().add_child(gem)

	# Health garantido
	var hp := HealthPickup.new()
	hp.global_position = global_position + Vector2(0, -10)
	get_parent().add_child(hp)

	# Power-up aleatório garantido
	var p := PowerUp.new()
	p.kind = POWERUP_BIAS[randi() % POWERUP_BIAS.size()]
	p.global_position = global_position + Vector2(0, 10)
	get_parent().add_child(p)

	queue_free()
