## Spread Cart — dispara N projéteis em leque na direção do inimigo mais próximo.
extends CartridgeBase

const BASE_INTERVAL := 1.4
const BASE_DAMAGE := 6
const SPREAD_ANGLE := PI / 6.0  # 30° total
const SEARCH_RADIUS := 200.0
const TINT := Color("#69f0ae")  # verde menta do spread

var _timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.4
	p_player.set_weapon_visual(Sprites.weapon_spread, TINT)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = BASE_INTERVAL * pow(0.92, level - 1)
	_fire()


func _projectile_count() -> int:
	return 3 + (level - 1)  # 3 -> 7


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 2) * player.damage_mult))


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	var base_dir: Vector2
	if target == null:
		base_dir = Vector2.RIGHT
	else:
		base_dir = (target.global_position - player.global_position).normalized()

	var count := _projectile_count()
	var dmg := _damage()
	var half := SPREAD_ANGLE * 0.5
	var step: float = SPREAD_ANGLE / max(1.0, float(count - 1))
	for i in count:
		var offset_angle: float = -half + step * float(i) if count > 1 else 0.0
		var dir := base_dir.rotated(offset_angle)
		var proj := Projectile.new()
		proj.tint = TINT
		proj.crit_chance = player.crit_chance
		proj.crit_mult = player.crit_mult
		proj.setup(player.global_position, dir, dmg, 260.0, 0)
		player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
