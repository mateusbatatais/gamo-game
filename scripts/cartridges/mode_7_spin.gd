## Mode 7 Spin — dispara projeteis numa espiral ao redor do player (efeito Mode 7).
extends CartridgeBase

const BASE_INTERVAL := 0.35
const BASE_DAMAGE := 5
const BASE_SPEED := 180.0
const SPIRAL_RATE := 2.2  # rad/s
const TINT := Color("#b388ff")  # roxo Mode 7

var _timer: float = 0.0
var _spiral_angle: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.1
	p_player.set_weapon_visual(Sprites.weapon_orbital, TINT)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_spiral_angle += SPIRAL_RATE * delta
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = BASE_INTERVAL * pow(0.92, level - 1)
	_fire()


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 2) * player.damage_mult))


func _projectile_count() -> int:
	return 1 + (level - 1) / 2  # 1, 1, 2, 2, 3


func _fire() -> void:
	var count := _projectile_count()
	var dmg := _damage()
	var step: float = TAU / float(max(1, count))
	for i in count:
		var angle: float = _spiral_angle + step * float(i)
		var dir := Vector2(cos(angle), sin(angle))
		var proj := Projectile.new()
		proj.tint = TINT
		proj.crit_chance = player.crit_chance
		proj.crit_mult = player.crit_mult
		proj.setup(player.global_position, dir, dmg, BASE_SPEED, 0)
		player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
