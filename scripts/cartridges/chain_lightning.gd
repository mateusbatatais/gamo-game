## Chain Lightning — projétil que arrebenta no inimigo e arca pra outros próximos.
## Cada arco causa dano reduzido (60% do anterior) e busca o próximo dentro do raio.
## Level escala dano base + chain_count.
extends CartridgeBase

const BASE_INTERVAL := 1.4
const BASE_DAMAGE := 14
const BASE_SPEED := 240.0
const SEARCH_RADIUS := 280.0
const CHAIN_RADIUS := 90.0
const TINT := Color("#00e5ff")

var _timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_timer = 0.3
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
	return int(roundf((BASE_DAMAGE + (level - 1) * 5) * player.damage_mult))


func _chain_count() -> int:
	return 2 + level  # nv1 = 3 inimigos no total, nv5 = 7


func _fire() -> void:
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	if target == null:
		return
	var dir := (target.global_position - player.global_position).normalized()
	var proj := LightningProjectile.new()
	proj.tint = TINT
	proj.crit_chance = player.crit_chance
	proj.crit_mult = player.crit_mult
	proj.chain_remaining = _chain_count()
	proj.chain_radius = CHAIN_RADIUS
	proj.setup(player.global_position, dir, _damage(), BASE_SPEED, 0)
	player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
