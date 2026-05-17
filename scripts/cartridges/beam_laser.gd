## Beam Laser — laser contínuo que aponta pro inimigo mais próximo e causa
## tick damage a cada 0.15s em quem estiver na linha. Visual de feixe constante.
## Level escala: damage por tick + raio de busca + largura do beam.
extends CartridgeBase

const SEARCH_RADIUS := 240.0
const TICK_INTERVAL := 0.15
const BASE_DAMAGE_PER_TICK := 3
const BEAM_WIDTH := 6.0
const TINT := Color("#e040fb")

var _tick_timer: float = 0.0
var _beam: BeamLaserVisual = null


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	p_player.set_weapon_visual(Sprites.weapon_blaster, TINT)
	_spawn_beam()


func on_level_up(new_level: int) -> void:
	super(new_level)
	if _beam != null and is_instance_valid(_beam):
		_beam.width = BEAM_WIDTH + (level - 1) * 1.2


func on_unequip() -> void:
	if _beam != null and is_instance_valid(_beam):
		_beam.queue_free()
	_beam = null


func _spawn_beam() -> void:
	_beam = BeamLaserVisual.new()
	_beam.color = TINT
	_beam.width = BEAM_WIDTH + (level - 1) * 1.2
	player.get_parent().add_child(_beam)


func _damage() -> int:
	return int(roundf((BASE_DAMAGE_PER_TICK + level - 1) * player.damage_mult))


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if _beam == null or not is_instance_valid(_beam):
		_spawn_beam()
	var target := player.find_nearest_enemy(SEARCH_RADIUS)
	if target == null:
		_beam.target_visible = false
		return
	_beam.set_endpoints(player.global_position, target.global_position)
	_beam.target_visible = true
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = TICK_INTERVAL
		_apply_tick(target.global_position)


## Aplica dano em todos inimigos próximos do segmento player→primary_target.
func _apply_tick(end: Vector2) -> void:
	var start: Vector2 = player.global_position
	var seg := end - start
	var seg_len: float = seg.length()
	if seg_len < 0.1:
		return
	var seg_dir := seg / seg_len
	var dmg := _damage()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Enemy):
			continue
		var enemy := e as Enemy
		if enemy._dying_anim:
			continue
		# Distância do ponto ao segmento (projeção limitada ao comprimento).
		var to_enemy := enemy.global_position - start
		var t: float = clampf(to_enemy.dot(seg_dir), 0.0, seg_len)
		var closest: Vector2 = start + seg_dir * t
		var dist: float = closest.distance_to(enemy.global_position)
		if dist <= BEAM_WIDTH * 1.5 + (level - 1) * 1.5:
			var is_crit: bool = randf() < player.crit_chance
			var final_dmg: int = int(round(float(dmg) * (player.crit_mult if is_crit else 1.0)))
			enemy.take_damage(final_dmg, Vector2.ZERO, is_crit)
	Audio.play(Audio.Sfx.HIT)
