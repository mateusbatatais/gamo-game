## Heat Seeker — projétil homing que persegue o inimigo mais próximo.
## Mais lento que o Star Blaster mas com dano maior e tracking.
extends CartridgeBase

const BASE_INTERVAL := 1.1
const BASE_DAMAGE := 12
const BASE_SPEED := 190.0
const SEARCH_RADIUS := 320.0
const TURN_RATE := 4.5
const TINT := Color("#ff5252")

var _timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.25
	p_player.set_weapon_visual(Sprites.weapon_mega, TINT)


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


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	if target == null:
		return
	var dir := (target.global_position - player.global_position).normalized()
	var proj := HomingProjectile.new()
	proj.tint = TINT
	proj.crit_chance = player.crit_chance
	proj.crit_mult = player.crit_mult
	proj.setup_homing(player.global_position, dir, _damage(), BASE_SPEED, TURN_RATE)
	player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
