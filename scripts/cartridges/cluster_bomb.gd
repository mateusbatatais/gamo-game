## Cluster Bomb — dispara um projétil "casca" que após X segundos explode em
## N estilhaços em estrela. Dano da casca é normal, estilhaços causam dano menor
## mas cobrem área. Level escala fragments e damage.
extends CartridgeBase

const BASE_INTERVAL := 1.6
const BASE_DAMAGE := 14
const BASE_SPEED := 220.0
const FUSE_TIME := 0.55
const SHRAPNEL_SPEED := 200.0
const SHRAPNEL_DAMAGE_RATIO := 0.5
const SEARCH_RADIUS := 280.0
const TINT := Color("#ff9800")

var _timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.35
	p_player.set_weapon_visual(Sprites.weapon_blaster, TINT)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = BASE_INTERVAL * pow(0.9, level - 1)
	_fire()


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 4) * player.damage_mult))


func _fragment_count() -> int:
	return 5 + level  # nv1 = 6, nv5 = 10


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	if target == null:
		return
	var dir := (target.global_position - player.global_position).normalized()
	var proj := ClusterBombProjectile.new()
	proj.tint = TINT
	proj.crit_chance = player.crit_chance
	proj.crit_mult = player.crit_mult
	proj.fuse_time = FUSE_TIME
	proj.fragment_count = _fragment_count()
	proj.shrapnel_speed = SHRAPNEL_SPEED
	proj.shrapnel_damage = int(round(float(_damage()) * SHRAPNEL_DAMAGE_RATIO))
	proj.setup(player.global_position, dir, _damage(), BASE_SPEED, 0)
	player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
