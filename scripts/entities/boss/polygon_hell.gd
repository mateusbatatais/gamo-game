## Boss da Era 3 (64-bit): Polygon Hell.
## Pirâmide corrompida que rotaciona, atira lasers em padrões geométricos,
## convoca Wireframe Hulks como minions na fase final.
## 3 fases: Stable / Glitching / Crashing.
class_name PolygonHell
extends Enemy

const BOSS_SPRITE_SCALE := 2.4

enum Phase { STABLE, GLITCHING, CRASHING }
enum Attack { LASER_SPIRAL, TRIANGLE_VOLLEY, SUMMON_HULKS, Z_BURST }

const PHASE_GLITCH := 0.66
const PHASE_CRASH := 0.33

const SPIRAL_PROJECTILES := 8
const SPIRAL_DAMAGE := 8
const SPIRAL_SPEED := 140.0

const TRIANGLE_DAMAGE := 14
const TRIANGLE_SPEED := 160.0

const Z_BURST_DAMAGE := 6
const Z_BURST_SPEED := 220.0

var _phase: Phase = Phase.STABLE
var _attack_cooldown: float = 3.0
var _rotation_speed: float = 1.2
var _arena_center: Vector2 = Vector2(320, 180)
var _hulks_spawned: int = 0


func _init() -> void:
	max_hp = 3000  # boss final da progressão de 3 fases
	contact_damage = 32
	move_speed = 0.0
	xp_value = 200
	token_value = 150
	body_radius = 30.0
	sprite_scale = BOSS_SPRITE_SCALE
	health_drop_chance = 0.0
	power_up_drop_chance = 0.0


func _ready() -> void:
	super()
	add_to_group("boss")
	_arena_center = ArenaBounds.get_rect().get_center()
	global_position = _arena_center
	EventBus.boss_spawned.emit(self)


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.add_frame("default", PixelArt.make_sprite(
		PackedStringArray(Sprites.POLYGON_HELL_IDLE[0]),
		Sprites.PALETTE_POLYGON_HELL
	))
	sprite.sprite_frames = sf
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	_update_phase()
	# Rotação visual constante
	if sprite != null:
		sprite.rotation += _rotation_speed * delta
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_attack_cooldown = _next_cooldown()
		_start_attack(_pick_attack())
	_update_flash(delta)


func _update_phase() -> void:
	var pct: float = float(current_hp) / float(max_hp)
	if pct <= PHASE_CRASH:
		_phase = Phase.CRASHING
		_rotation_speed = 2.4
	elif pct <= PHASE_GLITCH:
		_phase = Phase.GLITCHING
		_rotation_speed = 1.8
	else:
		_phase = Phase.STABLE
		_rotation_speed = 1.2


func _next_cooldown() -> float:
	match _phase:
		Phase.STABLE:
			return 2.5
		Phase.GLITCHING:
			return 1.7
		Phase.CRASHING:
			return 1.1
	return 2.5


func _pick_attack() -> Attack:
	match _phase:
		Phase.STABLE:
			return Attack.LASER_SPIRAL if randf() < 0.6 else Attack.TRIANGLE_VOLLEY
		Phase.GLITCHING:
			var r := randf()
			if r < 0.35:
				return Attack.LASER_SPIRAL
			elif r < 0.7:
				return Attack.TRIANGLE_VOLLEY
			else:
				return Attack.Z_BURST
		Phase.CRASHING:
			var r := randf()
			if r < 0.25:
				return Attack.SUMMON_HULKS
			elif r < 0.5:
				return Attack.Z_BURST
			elif r < 0.75:
				return Attack.TRIANGLE_VOLLEY
			else:
				return Attack.LASER_SPIRAL
	return Attack.LASER_SPIRAL


func _start_attack(a: Attack) -> void:
	match a:
		Attack.LASER_SPIRAL:
			_fire_spiral()
		Attack.TRIANGLE_VOLLEY:
			_fire_triangle()
		Attack.SUMMON_HULKS:
			_summon_hulks()
		Attack.Z_BURST:
			_z_burst()


## Espiral de projéteis em rotação contínua a partir do centro.
func _fire_spiral() -> void:
	var base_angle: float = sprite.rotation if sprite != null else 0.0
	for i in SPIRAL_PROJECTILES:
		var angle: float = base_angle + TAU * float(i) / float(SPIRAL_PROJECTILES)
		var dir := Vector2(cos(angle), sin(angle))
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, SPIRAL_DAMAGE, SPIRAL_SPEED)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)


## 3 projéteis em formação triangular focados no player.
func _fire_triangle() -> void:
	var player := _find_player()
	if player == null:
		return
	var base_dir := (player.global_position - global_position).normalized()
	var spread: float = PI / 8.0
	for offset in [-spread, 0.0, spread]:
		var dir := base_dir.rotated(offset)
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, TRIANGLE_DAMAGE, TRIANGLE_SPEED)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)


## Convoca 2 Wireframe Hulks como minions (só nas fases avançadas, max 6 total).
func _summon_hulks() -> void:
	if _hulks_spawned >= 6:
		# Substitui por outro ataque pra não passar batido.
		_fire_spiral()
		return
	for i in 2:
		var hulk := WireframeHulk.new()
		var angle: float = randf() * TAU
		hulk.global_position = global_position + Vector2(cos(angle), sin(angle)) * 80.0
		get_parent().add_child(hulk)
		_hulks_spawned += 1
	Audio.play(Audio.Sfx.LEVEL_UP)


## Z-burst — disparo rápido de projéteis fracos em padrão zigue-zague.
func _z_burst() -> void:
	var rect := ArenaBounds.get_rect()
	# 4 projéteis saindo das 4 bordas convergindo pro centro.
	var spawns := [
		[Vector2(rect.position.x, randf_range(rect.position.y, rect.end.y)), Vector2.RIGHT],
		[Vector2(rect.end.x, randf_range(rect.position.y, rect.end.y)), Vector2.LEFT],
		[Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y), Vector2.DOWN],
		[Vector2(randf_range(rect.position.x, rect.end.x), rect.end.y), Vector2.UP],
	]
	for spawn in spawns:
		var proj := EnemyProjectile.new()
		proj.setup(spawn[0], spawn[1], Z_BURST_DAMAGE, Z_BURST_SPEED)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)


func take_damage(amount: int, _knockback_dir: Vector2 = Vector2.ZERO, is_crit: bool = false) -> void:
	current_hp -= amount
	_flash_timer = 0.10 if is_crit else 0.06
	_spawn_damage_number(amount, is_crit)
	EventBus.boss_damaged.emit(current_hp, max_hp)
	if current_hp <= 0:
		_die()


func _die() -> void:
	Audio.play(Audio.Sfx.ENEMY_DIE)
	Audio.play(Audio.Sfx.LEVEL_UP)
	HitStop.freeze_big()
	HitStop.slow_mo_boss_death()
	GameState.register_kill()
	GameState.grant_tokens(token_value)
	EventBus.enemy_killed.emit(self, xp_value)
	# Fountain de XP gems abundante — boss final da run.
	for i in 20:
		var gem := XpGem.new()
		gem.value = 8
		var angle: float = TAU * float(i) / 20.0
		gem.global_position = global_position + Vector2(cos(angle), sin(angle)) * 24.0
		get_parent().add_child(gem)
	EventBus.boss_defeated.emit()
	queue_free()
