## Boss da Era 2 (32-bit CD): Bad Sector.
## Setor corrompido de um disco óptico — rotaciona em torno do player disparando
## "leitura óptica" (raios) e ocasionalmente faz "skip" (teleport + scratch burst).
## 3 fases: Reading / Stuttering / Crashed.
class_name BadSector
extends Enemy

const BOSS_SPRITE_SCALE := 2.6

enum Phase { READING, STUTTERING, CRASHED }
enum Attack { LASER_RING, OPTICAL_CROSS, SKIP_TELEPORT, SCRATCH_WAVE }

const PHASE_STUTTER := 0.66
const PHASE_CRASHED := 0.33

const LASER_RING_COUNT := 14
const LASER_DAMAGE := 7
const LASER_SPEED := 130.0

const OPTICAL_DAMAGE := 14
const OPTICAL_SPEED := 160.0

const SCRATCH_PROJ_DAMAGE := 6
const SCRATCH_PROJ_SPEED := 200.0

var _phase: Phase = Phase.READING
var _attack_cooldown: float = 3.0
var _orbit_angle: float = 0.0
var _orbit_radius: float = 100.0
var _orbit_speed: float = 0.6  # rad/s
var _arena_center: Vector2 = Vector2(320, 180)


func _init() -> void:
	max_hp = 2400  # mais do que Fragmentation (final boss da run)
	contact_damage = 30
	move_speed = 0.0  # não persegue, orbita
	xp_value = 150
	token_value = 100
	body_radius = 28.0
	sprite_scale = BOSS_SPRITE_SCALE
	health_drop_chance = 0.0
	power_up_drop_chance = 0.0


func _ready() -> void:
	super()
	add_to_group("boss")
	_orbit_angle = randf() * TAU
	_arena_center = ArenaBounds.get_rect().get_center()
	global_position = _arena_center + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * _orbit_radius
	EventBus.boss_spawned.emit(self)


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.BAD_SECTOR_IDLE, Sprites.PALETTE_BAD_SECTOR, 3.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	_update_phase()
	# Orbita lentamente em torno do centro da arena.
	_orbit_angle += _orbit_speed * delta
	var target_pos := _arena_center + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * _orbit_radius
	# Suaviza movimento
	global_position = global_position.lerp(target_pos, 0.05)
	# Sprite rotaciona pra dar feel de disco lendo
	if sprite != null:
		sprite.rotation += delta * 1.2
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_attack_cooldown = _next_cooldown()
		_start_attack(_pick_attack())
	_update_flash(delta)


func _update_phase() -> void:
	var pct: float = float(current_hp) / float(max_hp)
	if pct <= PHASE_CRASHED:
		_phase = Phase.CRASHED
		_orbit_speed = 1.6
	elif pct <= PHASE_STUTTER:
		_phase = Phase.STUTTERING
		_orbit_speed = 1.0
	else:
		_phase = Phase.READING
		_orbit_speed = 0.6


func _next_cooldown() -> float:
	match _phase:
		Phase.READING:
			return 2.8
		Phase.STUTTERING:
			return 1.9
		Phase.CRASHED:
			return 1.2
	return 2.8


func _pick_attack() -> Attack:
	match _phase:
		Phase.READING:
			return Attack.LASER_RING if randf() < 0.7 else Attack.OPTICAL_CROSS
		Phase.STUTTERING:
			var r := randf()
			if r < 0.4:
				return Attack.LASER_RING
			elif r < 0.7:
				return Attack.OPTICAL_CROSS
			else:
				return Attack.SKIP_TELEPORT
		Phase.CRASHED:
			var r := randf()
			if r < 0.3:
				return Attack.LASER_RING
			elif r < 0.55:
				return Attack.SKIP_TELEPORT
			elif r < 0.8:
				return Attack.SCRATCH_WAVE
			else:
				return Attack.OPTICAL_CROSS
	return Attack.LASER_RING


func _start_attack(a: Attack) -> void:
	match a:
		Attack.LASER_RING:
			_fire_laser_ring()
		Attack.OPTICAL_CROSS:
			_fire_optical_cross()
		Attack.SKIP_TELEPORT:
			_skip_teleport()
		Attack.SCRATCH_WAVE:
			_scratch_wave()


## Ring de "leitura óptica" — projéteis irradiando em 360°.
func _fire_laser_ring() -> void:
	var spin: float = randf() * (TAU / float(LASER_RING_COUNT))
	for i in LASER_RING_COUNT:
		var angle: float = TAU * float(i) / float(LASER_RING_COUNT) + spin
		var dir := Vector2(cos(angle), sin(angle))
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, LASER_DAMAGE, LASER_SPEED)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)


## Cross focado no player — 4 projéteis em "cruz" centrada no player.
func _fire_optical_cross() -> void:
	var player := _find_player()
	if player == null:
		return
	var to_player := (player.global_position - global_position).normalized()
	var perp := Vector2(-to_player.y, to_player.x)
	# 4 projéteis: pra frente, atrás, lateral esquerda e direita relativos ao boss.
	var dirs := [to_player, -to_player, perp, -perp]
	for d in dirs:
		var proj := EnemyProjectile.new()
		proj.setup(global_position, d, OPTICAL_DAMAGE, OPTICAL_SPEED)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)


## Skip — teleporta pra outro ponto da órbita (efeito disco pulando).
func _skip_teleport() -> void:
	_orbit_angle += PI + randf_range(-0.6, 0.6)
	global_position = _arena_center + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * _orbit_radius
	# Flash branco no sprite + small burst
	_flash_timer = 0.18
	for i in 4:
		var a: float = TAU * float(i) / 4.0 + randf() * 0.3
		var d := Vector2(cos(a), sin(a))
		var proj := EnemyProjectile.new()
		proj.setup(global_position, d, LASER_DAMAGE, LASER_SPEED * 1.2)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.DASH)


## Scratch Wave (fase Crashed) — spawna 3-4 Scratches voando pela arena.
func _scratch_wave() -> void:
	var rect := ArenaBounds.get_rect()
	for i in 4:
		var scratch := Scratch.new()
		var side: float = -1.0 if randf() < 0.5 else 1.0
		var x: float = rect.position.x - 16 if side < 0 else rect.end.x + 16
		var y: float = randf_range(rect.position.y + 30, rect.end.y - 30)
		scratch.global_position = Vector2(x, y)
		get_parent().add_child(scratch)
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
	# Fountain de XP — boss final da run dropa MUITO XP.
	for i in 16:
		var gem := XpGem.new()
		gem.value = 6
		var angle: float = TAU * float(i) / 16.0
		gem.global_position = global_position + Vector2(cos(angle), sin(angle)) * 22.0
		get_parent().add_child(gem)
	EventBus.boss_defeated.emit()
	queue_free()
