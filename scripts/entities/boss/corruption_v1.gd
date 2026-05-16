## Boss da Era 8-bit: Corruption v1.0.
## Estende Enemy mas com HP alto, padrões de ataque rotativos, e vitória ao morrer.
class_name CorruptionV1
extends Enemy

const BOSS_SPRITE_SCALE := 3.0

enum Phase { OPENING, MIDGAME, FINAL }
enum Attack { RING, CHARGE, MINIONS }

# --- Configuração de fases ---
const PHASE_BREAKPOINT_MID := 0.66  # % HP
const PHASE_BREAKPOINT_FINAL := 0.33

# --- Ataques ---
const RING_PROJECTILE_COUNT := 12
const RING_DAMAGE := 8
const RING_SPEED := 95.0

const CHARGE_TELEGRAPH := 0.8
const CHARGE_DURATION := 0.55
const CHARGE_SPEED := 260.0

const MINION_SPAWN_COUNT := 4

var _phase: Phase = Phase.OPENING
var _attack_cooldown: float = 3.0
var _attack_in_progress: bool = false
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_phase_timer: float = 0.0
var _charge_state: int = 0  # 0=idle 1=telegraph 2=charging

signal defeated


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO, is_crit: bool = false) -> void:
	super(amount, knockback_dir, is_crit)
	EventBus.boss_damaged.emit(current_hp, max_hp)


func _init() -> void:
	max_hp = 800
	contact_damage = 18
	move_speed = 25.0
	xp_value = 50
	body_radius = 22.0
	sprite_scale = BOSS_SPRITE_SCALE


func _ready() -> void:
	super()
	add_to_group("boss")
	EventBus.boss_spawned.emit(self)


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.BOSS_IDLE, Sprites.PALETTE_BOSS, 2.5
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	_update_phase()
	_handle_attacks(delta)
	if _charge_state == 2:
		velocity = _charge_dir * CHARGE_SPEED
	elif _attack_in_progress:
		velocity = Vector2.ZERO
	else:
		_chase_player(delta)
	_update_flash(delta)
	move_and_slide()


func _update_phase() -> void:
	var pct: float = float(current_hp) / float(max_hp)
	if pct <= PHASE_BREAKPOINT_FINAL:
		_phase = Phase.FINAL
	elif pct <= PHASE_BREAKPOINT_MID:
		_phase = Phase.MIDGAME
	else:
		_phase = Phase.OPENING


func _handle_attacks(delta: float) -> void:
	if _attack_in_progress:
		_advance_attack(delta)
		return
	_attack_cooldown -= delta
	if _attack_cooldown > 0.0:
		return
	_start_attack(_pick_attack())


func _pick_attack() -> Attack:
	match _phase:
		Phase.OPENING:
			return Attack.RING
		Phase.MIDGAME:
			return Attack.RING if randf() < 0.55 else Attack.CHARGE
		Phase.FINAL:
			var r := randf()
			if r < 0.4:
				return Attack.RING
			elif r < 0.75:
				return Attack.CHARGE
			else:
				return Attack.MINIONS
	return Attack.RING


func _start_attack(a: Attack) -> void:
	_attack_in_progress = true
	match a:
		Attack.RING:
			_fire_ring()
			_attack_cooldown = _next_cooldown()
			_attack_in_progress = false
		Attack.CHARGE:
			_begin_charge()
		Attack.MINIONS:
			_spawn_minions()
			_attack_cooldown = _next_cooldown()
			_attack_in_progress = false


func _next_cooldown() -> float:
	match _phase:
		Phase.OPENING:
			return 3.5
		Phase.MIDGAME:
			return 2.6
		Phase.FINAL:
			return 1.8
	return 3.0


func _fire_ring() -> void:
	for i in RING_PROJECTILE_COUNT:
		var angle: float = TAU * float(i) / float(RING_PROJECTILE_COUNT)
		var dir := Vector2(cos(angle), sin(angle))
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, RING_DAMAGE, RING_SPEED)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)


func _begin_charge() -> void:
	var player := _find_player()
	if player == null:
		_attack_in_progress = false
		_attack_cooldown = 1.0
		return
	_charge_dir = (player.global_position - global_position).normalized()
	_charge_state = 1
	_charge_phase_timer = CHARGE_TELEGRAPH
	if sprite != null:
		sprite.modulate = Color(2.0, 0.4, 0.4, 1.0)


func _advance_attack(delta: float) -> void:
	if _charge_state == 0:
		_attack_in_progress = false
		return
	_charge_phase_timer -= delta
	if _charge_phase_timer > 0.0:
		return
	if _charge_state == 1:
		# Telegraph terminou → começa a carga
		_charge_state = 2
		_charge_phase_timer = CHARGE_DURATION
		if sprite != null:
			sprite.modulate = Color.WHITE
	else:
		# Charge terminou
		_charge_state = 0
		_attack_in_progress = false
		_attack_cooldown = _next_cooldown() * 0.7


func _spawn_minions() -> void:
	for i in MINION_SPAWN_COUNT:
		var angle: float = TAU * float(i) / float(MINION_SPAWN_COUNT)
		var artifact := Artifact.new()
		artifact.global_position = global_position + Vector2(cos(angle), sin(angle)) * 40.0
		get_parent().add_child(artifact)
	Audio.play(Audio.Sfx.LEVEL_UP)


func _chase_player(_delta: float) -> void:
	var player := _find_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	var dir := player.global_position - global_position
	if dir.length_squared() < 1.0:
		velocity = Vector2.ZERO
		return
	# Move mais devagar nas fases iniciais
	var speed_mult: float = 1.0
	if _phase == Phase.FINAL:
		speed_mult = 1.6
	elif _phase == Phase.MIDGAME:
		speed_mult = 1.2
	velocity = dir.normalized() * move_speed * speed_mult


func _die() -> void:
	Audio.play(Audio.Sfx.ENEMY_DIE)
	Audio.play(Audio.Sfx.LEVEL_UP)
	HitStop.freeze_big()
	HitStop.slow_mo_boss_death()
	GameState.register_kill()
	GameState.grant_tokens(token_value)
	EventBus.enemy_killed.emit(self, xp_value)
	# Solta múltiplas gemas pra um "fountain" final
	for i in 8:
		var gem := XpGem.new()
		gem.value = 5
		var angle: float = TAU * float(i) / 8.0
		gem.global_position = global_position + Vector2(cos(angle), sin(angle)) * 18.0
		get_parent().add_child(gem)
	defeated.emit()
	EventBus.boss_defeated.emit()
	queue_free()
