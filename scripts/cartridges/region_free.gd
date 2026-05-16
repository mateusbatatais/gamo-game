## Region Free — projeteis aceleram com o tempo de voo + piercing.
## Drop lendario do boss Fragmentation.
extends CartridgeBase

const BASE_INTERVAL := 0.7
const BASE_DAMAGE := 12
const INITIAL_SPEED := 90.0
const TARGET_SPEED := 360.0
const ACCEL_TIME := 0.6
const SEARCH_RADIUS := 240.0
const TINT := Color("#ff5252")  # vermelho Region Free

var _timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.2
	p_player.set_weapon_visual(Sprites.weapon_mega, TINT)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = BASE_INTERVAL * pow(0.92, level - 1)
	_fire()


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 4) * player.damage_mult))


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	if target == null:
		return
	var dir := (target.global_position - player.global_position).normalized()
	var proj := AcceleratingProjectile.new()
	proj.tint = TINT
	proj.crit_chance = player.crit_chance
	proj.crit_mult = player.crit_mult
	proj.setup_accel(
		player.global_position, dir, _damage(),
		INITIAL_SPEED, TARGET_SPEED, ACCEL_TIME, 2 + level
	)
	player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
