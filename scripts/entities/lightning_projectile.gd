## Projétil de Chain Lightning. Ao acertar, "arca" pra inimigos próximos
## causando dano reduzido em cada salto.
class_name LightningProjectile
extends Projectile

var chain_remaining: int = 3
var chain_radius: float = 90.0
const CHAIN_DAMAGE_FALLOFF := 0.6  ## cada arco causa 60% do anterior


## Override do hit: ao acertar, gera arco visual + busca próximo alvo.
func _on_body_entered(body: Node2D) -> void:
	if body in _hits:
		return
	if not (body is Enemy):
		return
	_hits.append(body)
	var is_crit: bool = randf() < crit_chance
	var final_dmg: int = int(round(float(damage) * (crit_mult if is_crit else 1.0)))
	(body as Enemy).take_damage(final_dmg, Vector2.ZERO, is_crit)
	Audio.play(Audio.Sfx.HIT)
	# Chain
	_arc_from(body as Enemy, final_dmg)
	queue_free()


## Procura o próximo alvo a partir de `from` e dispara um arco visual + dano.
func _arc_from(from: Enemy, current_dmg: int) -> void:
	if chain_remaining <= 0:
		return
	var next_dmg: int = int(round(float(current_dmg) * CHAIN_DAMAGE_FALLOFF))
	if next_dmg <= 0:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Enemy = null
	var best_d: float = chain_radius
	for e in enemies:
		if not (e is Enemy) or e in _hits:
			continue
		var enemy := e as Enemy
		if enemy._dying_anim:
			continue
		var d: float = from.global_position.distance_to(enemy.global_position)
		if d < best_d:
			best_d = d
			best = enemy
	if best == null:
		return
	_hits.append(best)
	# Spawn arco visual
	var arc := _LightningArc.new()
	arc.setup(from.global_position, best.global_position, tint)
	get_parent().add_child(arc)
	var crit_next: bool = randf() < crit_chance
	var dmg_dealt: int = int(round(float(next_dmg) * (crit_mult if crit_next else 1.0)))
	best.take_damage(dmg_dealt, Vector2.ZERO, crit_next)
	chain_remaining -= 1
	# Recursão: continua a corrente até esgotar
	_arc_from(best, next_dmg)


## Arco visual que aparece entre dois pontos por 120ms.
class _LightningArc extends Node2D:
	const LIFETIME := 0.12
	var _age: float = 0.0
	var _from: Vector2 = Vector2.ZERO
	var _to: Vector2 = Vector2.ZERO
	var _color: Color = Color.WHITE

	func setup(p_from: Vector2, p_to: Vector2, p_color: Color) -> void:
		_from = p_from
		_to = p_to
		_color = p_color
		z_index = 5

	func _process(delta: float) -> void:
		_age += delta
		if _age >= LIFETIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t: float = 1.0 - (_age / LIFETIME)
		var col := Color(_color.r, _color.g, _color.b, t)
		# Linha quebrada zig-zag pra dar feel de relâmpago.
		var dir := (_to - _from)
		var steps: int = 4
		var prev: Vector2 = _from - position
		for i in range(1, steps + 1):
			var s: float = float(i) / float(steps)
			var mid := _from + dir * s
			var perp := dir.orthogonal().normalized() * randf_range(-5.0, 5.0)
			var to_local := (mid + perp) - position
			draw_line(prev, to_local, col, 2.0)
			prev = to_local
