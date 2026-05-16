## Mega Blaster — evolução de Star Blaster + Power Glove.
## Laser piercing forte e rápido que atravessa fileiras.
extends CartridgeBase

const BASE_INTERVAL := 0.6
const BASE_DAMAGE := 22
const BASE_SPEED := 360.0
const BASE_PIERCE := 4
const SEARCH_RADIUS := 280.0
const TINT := Color("#00e5ff")  # ciano elétrico do laser

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
	_timer = BASE_INTERVAL * pow(0.9, level - 1)
	_fire()


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 6) * player.damage_mult))


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	if target == null:
		return
	var dir := (target.global_position - player.global_position).normalized()
	var proj := Projectile.new()
	proj.tint = TINT
	proj.crit_chance = player.crit_chance
	proj.crit_mult = player.crit_mult
	proj.setup(player.global_position, dir, _damage(), BASE_SPEED, BASE_PIERCE + level - 1)
	player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
