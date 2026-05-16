## Stereo Sound — dispara 2 projeteis paralelos que se afastam levemente.
extends CartridgeBase

const BASE_INTERVAL := 0.8
const BASE_DAMAGE := 7
const BASE_SPEED := 220.0
const SEPARATION := 14.0
const SEARCH_RADIUS := 220.0
const TINT := Color("#ff80ab")  # rosa estéreo

var _timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.25
	p_player.set_weapon_visual(Sprites.weapon_spread, TINT)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = BASE_INTERVAL * pow(0.9, level - 1)
	_fire()


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 2) * player.damage_mult))


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	var base_dir: Vector2
	if target == null:
		base_dir = Vector2.RIGHT
	else:
		base_dir = (target.global_position - player.global_position).normalized()
	var perp := Vector2(-base_dir.y, base_dir.x)
	var dmg := _damage()
	for side in [-1.0, 1.0]:
		var origin: Vector2 = player.global_position + perp * SEPARATION * side
		var proj := Projectile.new()
		proj.tint = TINT
		proj.crit_chance = player.crit_chance
		proj.crit_mult = player.crit_mult
		proj.setup(origin, base_dir, dmg, BASE_SPEED, 0)
		player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
