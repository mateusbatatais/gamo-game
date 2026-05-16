## Star Blaster — projétil reto no inimigo mais próximo.
extends CartridgeBase

const BASE_INTERVAL := 0.85
const BASE_DAMAGE := 8
const BASE_SPEED := 280.0
const SEARCH_RADIUS := 240.0
const TINT := Color("#ffeb3b")  # amarelo do blaster básico

var _timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.2
	p_player.set_weapon_visual(Sprites.weapon_blaster, TINT)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = _interval()
	_fire()


func _interval() -> float:
	return BASE_INTERVAL * pow(0.88, level - 1)


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 3) * player.damage_mult))


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	if target == null:
		return
	var dir := (target.global_position - player.global_position).normalized()
	var proj := Projectile.new()
	proj.tint = TINT
	proj.crit_chance = player.crit_chance
	proj.crit_mult = player.crit_mult
	proj.setup(player.global_position, dir, _damage(), BASE_SPEED, 0)
	player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
