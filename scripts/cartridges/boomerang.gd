## Boomerang — projétil que vai, freia e volta pro player. Atravessa inimigos
## acertando tanto na ida quanto na volta. Bom contra grupos enfileirados.
extends CartridgeBase

const BASE_INTERVAL := 1.4
const BASE_DAMAGE := 9
const SEARCH_RADIUS := 260.0
const TINT := Color("#80deea")

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
	_timer = BASE_INTERVAL * pow(0.92, level - 1)
	_fire()


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 2) * player.damage_mult))


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	var dir: Vector2 = Vector2.RIGHT
	if target != null:
		dir = (target.global_position - player.global_position).normalized()
	var proj := BoomerangProjectile.new()
	proj.tint = TINT
	proj.crit_chance = player.crit_chance
	proj.crit_mult = player.crit_mult
	proj.setup_boomerang(player, dir, _damage())
	player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
