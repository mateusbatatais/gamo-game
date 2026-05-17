## Burst Rifle — dispara 3 tiros em rajada rápida (200ms entre cada),
## depois pausa um ciclo maior. Bom dano cumulativo, mas requer mirar bem.
extends CartridgeBase

const BASE_INTERVAL := 1.5  ## tempo entre rajadas
const BURST_DELAY := 0.10   ## tempo entre tiros da mesma rajada
const BASE_DAMAGE := 7
const BASE_SPEED := 320.0
const SEARCH_RADIUS := 260.0
const TINT := Color("#9bbc0f")

var _timer: float = 0.0
var _burst_left: int = 0
var _burst_timer: float = 0.0
var _burst_dir: Vector2 = Vector2.RIGHT


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.2
	p_player.set_weapon_visual(Sprites.weapon_blaster, TINT)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	# Rajada em andamento — dispara os tiros restantes.
	if _burst_left > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_fire_single(_burst_dir)
			_burst_left -= 1
			_burst_timer = BURST_DELAY
		return
	# Senão, conta tempo até próxima rajada.
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = BASE_INTERVAL * pow(0.92, level - 1)
	_start_burst()


func _burst_size() -> int:
	return 3 + (level - 1)  # nv1 = 3, nv5 = 7 tiros na rajada


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 2) * player.damage_mult))


func _start_burst() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	if target == null:
		return
	_burst_dir = (target.global_position - player.global_position).normalized()
	_burst_left = _burst_size()
	_burst_timer = 0.0  # dispara o primeiro tiro no próximo frame


func _fire_single(dir: Vector2) -> void:
	var proj := Projectile.new()
	proj.tint = TINT
	proj.crit_chance = player.crit_chance
	proj.crit_mult = player.crit_mult
	# Pequeno spread aleatório pra dar feel de recoil.
	var spread := dir.rotated(randf_range(-0.08, 0.08))
	proj.setup(player.global_position, spread, _damage(), BASE_SPEED, 0)
	player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
