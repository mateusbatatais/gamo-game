## Sonic Boom — evolução de Stereo Sound + Power Glove.
## 4 projeteis paralelos com dano alto e fire rate elevado.
extends CartridgeBase

const BASE_INTERVAL := 0.5
const BASE_DAMAGE := 14
const BASE_SPEED := 260.0
const SEPARATION := 10.0
const SEARCH_RADIUS := 250.0
const TINT := Color("#f50057")  # magenta sônico

var _timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.15
	p_player.set_weapon_visual(Sprites.weapon_mega, TINT)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = BASE_INTERVAL * pow(0.88, level - 1)
	_fire()


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 5) * player.damage_mult))


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	var base_dir: Vector2
	if target == null:
		base_dir = Vector2.RIGHT
	else:
		base_dir = (target.global_position - player.global_position).normalized()
	var perp := Vector2(-base_dir.y, base_dir.x)
	var dmg := _damage()
	# 4 projéteis paralelos: -1.5, -0.5, +0.5, +1.5 offsets
	for offset in [-1.5, -0.5, 0.5, 1.5]:
		var origin: Vector2 = player.global_position + perp * SEPARATION * offset
		var proj := Projectile.new()
		proj.tint = TINT
		proj.crit_chance = player.crit_chance
		proj.crit_mult = player.crit_mult
		proj.setup(origin, base_dir, dmg, BASE_SPEED, 1)
		player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
