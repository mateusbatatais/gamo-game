## Boss da Era 16-bit: Fragmentation.
## 4 fases (Whole/Cracked/Shattered/Final). Na fase Final, divide-se em 4 Fragments.
class_name Fragmentation
extends Enemy

const BOSS_SPRITE_SCALE := 3.0  # maior que antes (2.4) — boss imponente

enum Phase { WHOLE, CRACKED, SHATTERED, FINAL }
enum Attack { FRAG_BURST, CROSSFIRE, PHASE_DASH, SPIRAL_RAIN }

const PHASE_CRACKED := 0.66
const PHASE_SHATTERED := 0.33

# Boss buffado: mais projéteis, mais dano, mais velocidade.
const FRAG_BURST_COUNT := 16  # era 12
const FRAG_BURST_DAMAGE := 8  # era 6
const FRAG_BURST_SPEED := 120.0  # era 105

const CROSSFIRE_DAMAGE := 18  # era 14
const CROSSFIRE_SPEED := 150.0  # era 130

const PHASE_DASH_TELEPORT_RANGE := 80.0
const PHASE_DASH_LUNGE_SPEED := 340.0
const PHASE_DASH_DURATION := 0.45

# Novo ataque "Spiral Rain": rajada contínua em espiral durante 2.5s
const SPIRAL_RAIN_DURATION := 2.5
const SPIRAL_RAIN_INTERVAL := 0.10
const SPIRAL_RAIN_DAMAGE := 7
const SPIRAL_RAIN_SPEED := 130.0

const FRAGMENT_COUNT := 5  # era 4

var _phase: Phase = Phase.WHOLE
var _attack_cooldown: float = 3.0
var _attack_in_progress: bool = false
var _lunge_dir: Vector2 = Vector2.ZERO
var _lunge_timer: float = 0.0
var _split_triggered: bool = false
var _dying: bool = false
var _spiral_timer: float = 0.0
var _spiral_remaining: float = 0.0
var _spiral_angle: float = 0.0

signal defeated


func _init() -> void:
	# HP +66% e mais dano contato — boss agora exige uma luta de verdade.
	max_hp = 2000  # era 1200
	contact_damage = 28  # era 20
	move_speed = 38.0  # era 30
	xp_value = 120  # era 80
	token_value = 80  # boss derruba uma boa pilha de tokens
	body_radius = 30.0  # era 26
	sprite_scale = BOSS_SPRITE_SCALE
	health_drop_chance = 0.0
	power_up_drop_chance = 0.0


func _ready() -> void:
	super()
	add_to_group("boss")
	EventBus.boss_spawned.emit(self)


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.add_frame("default", PixelArt.make_sprite(
		PackedStringArray(Sprites.FRAGMENTATION_IDLE[0]),
		Sprites.PALETTE_FRAGMENTATION
	))
	sprite.sprite_frames = sf
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _physics_process(delta: float) -> void:
	if _split_triggered:
		# Boss invisível durante fase Final — fragments fazem o trabalho
		_check_fragments()
		return
	_update_phase()
	_update_spiral_rain(delta)
	_handle_attacks(delta)
	if _lunge_timer > 0.0:
		velocity = _lunge_dir * PHASE_DASH_LUNGE_SPEED
		_lunge_timer -= delta
	elif _attack_in_progress or _spiral_remaining > 0.0:
		velocity = Vector2.ZERO
	else:
		_chase_player(delta)
	_update_flash(delta)
	move_and_slide()


## Mantém o ataque Spiral Rain disparando enquanto _spiral_remaining > 0.
func _update_spiral_rain(delta: float) -> void:
	if _spiral_remaining <= 0.0:
		return
	_spiral_remaining -= delta
	_spiral_timer -= delta
	_spiral_angle += delta * 6.0
	if _spiral_timer <= 0.0:
		_spiral_timer = SPIRAL_RAIN_INTERVAL
		_fire_spiral_pair()


func _update_phase() -> void:
	var pct: float = float(current_hp) / float(max_hp)
	if pct <= PHASE_SHATTERED:
		_phase = Phase.SHATTERED
	elif pct <= PHASE_CRACKED:
		_phase = Phase.CRACKED
	else:
		_phase = Phase.WHOLE


func _handle_attacks(delta: float) -> void:
	if _attack_in_progress:
		_attack_in_progress = false  # ataques são instantâneos exceto dash
		return
	_attack_cooldown -= delta
	if _attack_cooldown > 0.0:
		return
	_start_attack(_pick_attack())


func _pick_attack() -> Attack:
	match _phase:
		Phase.WHOLE:
			# Já não é mais só FRAG_BURST — mistura com Spiral Rain pra variar.
			return Attack.FRAG_BURST if randf() < 0.7 else Attack.SPIRAL_RAIN
		Phase.CRACKED:
			var r := randf()
			if r < 0.45:
				return Attack.FRAG_BURST
			elif r < 0.75:
				return Attack.PHASE_DASH
			else:
				return Attack.SPIRAL_RAIN
		Phase.SHATTERED:
			var r := randf()
			if r < 0.3:
				return Attack.FRAG_BURST
			elif r < 0.55:
				return Attack.CROSSFIRE
			elif r < 0.8:
				return Attack.PHASE_DASH
			else:
				return Attack.SPIRAL_RAIN
	return Attack.FRAG_BURST


func _start_attack(a: Attack) -> void:
	match a:
		Attack.FRAG_BURST:
			_fire_frag_burst()
		Attack.CROSSFIRE:
			_fire_crossfire()
		Attack.PHASE_DASH:
			_phase_dash()
		Attack.SPIRAL_RAIN:
			_start_spiral_rain()
	_attack_cooldown = _next_cooldown()


func _next_cooldown() -> float:
	match _phase:
		Phase.WHOLE:
			return 2.6
		Phase.CRACKED:
			return 1.7
		Phase.SHATTERED:
			return 1.05
	return 2.6


func _start_spiral_rain() -> void:
	_spiral_remaining = SPIRAL_RAIN_DURATION
	_spiral_timer = 0.0
	_spiral_angle = randf() * TAU


func _fire_spiral_pair() -> void:
	# Dois projéteis em espiral opostos
	for offset in [0.0, PI]:
		var ang: float = _spiral_angle + offset
		var dir := Vector2(cos(ang), sin(ang))
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, SPIRAL_RAIN_DAMAGE, SPIRAL_RAIN_SPEED)
		get_parent().add_child(proj)


func _fire_frag_burst() -> void:
	var spin: float = randf() * TAU * 0.1  # leve variação
	for i in FRAG_BURST_COUNT:
		var angle: float = TAU * float(i) / float(FRAG_BURST_COUNT) + spin
		var dir := Vector2(cos(angle), sin(angle))
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, FRAG_BURST_DAMAGE, FRAG_BURST_SPEED)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)


func _fire_crossfire() -> void:
	# 4 projéteis nas direções cardeais (mais fortes)
	var directions := [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	for dir in directions:
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, CROSSFIRE_DAMAGE, CROSSFIRE_SPEED)
		get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)


func _phase_dash() -> void:
	var player := _find_player()
	if player == null:
		return
	# Teleporta pra fora do player, depois lunge
	var to: Vector2 = (global_position - player.global_position).normalized()
	if to.length_squared() < 0.01:
		to = Vector2.RIGHT
	var teleport_pos: Vector2 = player.global_position + to * PHASE_DASH_TELEPORT_RANGE
	var rect: Rect2 = ArenaBounds.get_rect()
	teleport_pos.x = clampf(teleport_pos.x, rect.position.x + 40, rect.end.x - 40)
	teleport_pos.y = clampf(teleport_pos.y, rect.position.y + 40, rect.end.y - 40)
	global_position = teleport_pos
	_lunge_dir = (player.global_position - global_position).normalized()
	_lunge_timer = PHASE_DASH_DURATION


func _chase_player(_delta: float) -> void:
	var player := _find_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	var dir := player.global_position - global_position
	if dir.length_squared() < 1.0:
		velocity = Vector2.ZERO
		return
	var speed_mult: float = 1.0
	if _phase == Phase.SHATTERED:
		speed_mult = 1.5
	elif _phase == Phase.CRACKED:
		speed_mult = 1.2
	velocity = dir.normalized() * move_speed * speed_mult


func take_damage(amount: int, _knockback_dir: Vector2 = Vector2.ZERO, is_crit: bool = false) -> void:
	if _split_triggered:
		return  # imune durante fase Final (mate os fragments)
	current_hp -= amount
	_flash_timer = 0.10 if is_crit else 0.06
	_spawn_damage_number(amount, is_crit)
	EventBus.boss_damaged.emit(current_hp, max_hp)
	if current_hp <= 0:
		_trigger_split()


func _trigger_split() -> void:
	_split_triggered = true
	if sprite != null:
		sprite.visible = false
	Audio.play(Audio.Sfx.LEVEL_UP)
	# Spawna 4 Fragments em torno
	for i in FRAGMENT_COUNT:
		var angle: float = TAU * float(i) / float(FRAGMENT_COUNT)
		var fragment := FragmentationFragment.new()
		fragment.global_position = global_position + Vector2(cos(angle), sin(angle)) * 50.0
		get_parent().add_child(fragment)


func _check_fragments() -> void:
	if _dying:
		return
	var fragments := get_tree().get_nodes_in_group("boss_fragments")
	if fragments.is_empty():
		_dying = true
		_die()


func _die() -> void:
	Audio.play(Audio.Sfx.ENEMY_DIE)
	Audio.play(Audio.Sfx.LEVEL_UP)
	HitStop.freeze_big()
	# Slow-mo de quase 1s após o freeze pra saborear a vitória.
	HitStop.slow_mo_boss_death()
	GameState.register_kill()
	GameState.grant_tokens(token_value)
	EventBus.enemy_killed.emit(self, xp_value)
	# Fountain de XP gems
	for i in 12:
		var gem := XpGem.new()
		gem.value = 5
		var angle: float = TAU * float(i) / 12.0
		gem.global_position = global_position + Vector2(cos(angle), sin(angle)) * 22.0
		get_parent().add_child(gem)
	defeated.emit()
	EventBus.boss_defeated.emit()
	queue_free()
