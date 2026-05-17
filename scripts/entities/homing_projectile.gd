## Projétil que persegue o inimigo mais próximo, ajustando direção a cada frame
## com uma taxa de giro limitada (não vira instantaneamente).
class_name HomingProjectile
extends Projectile

var turn_rate: float = 4.0  # rad/s
var seek_radius: float = 320.0
var _target: Enemy = null


func setup_homing(
	start_pos: Vector2,
	dir: Vector2,
	p_damage: int,
	p_speed: float,
	p_turn_rate: float
) -> void:
	setup(start_pos, dir, p_damage, p_speed, 0)
	turn_rate = p_turn_rate
	# Não busca alvo aqui — o cartucho chama setup antes de add_child, então
	# get_tree() seria null. _physics_process busca lazy no primeiro frame.


func _physics_process(delta: float) -> void:
	# Se perdeu o alvo (ou nunca teve), tenta de novo a cada frame.
	if _target == null or not is_instance_valid(_target):
		_target = _find_target()
	# Ajusta direção em direção ao alvo, limitado pela turn_rate.
	var turn_intensity: float = 0.0
	if _target != null and is_instance_valid(_target):
		var desired := (_target.global_position - global_position).normalized()
		var current_angle: float = direction.angle()
		var desired_angle: float = desired.angle()
		var diff: float = wrapf(desired_angle - current_angle, -PI, PI)
		var max_step: float = turn_rate * delta
		var actual_step: float = clampf(diff, -max_step, max_step)
		direction = direction.rotated(actual_step)
		rotation = direction.angle()
		# Smear: quanto mais a curva, mais esticado horizontal (na direção do movimento).
		# Normaliza por max_step pra obter [0..1] de "intensidade da virada".
		turn_intensity = clampf(abs(actual_step) / max_step, 0.0, 1.0) if max_step > 0.0 else 0.0
	_apply_smear(delta, turn_intensity)
	# Movimento padrão do Projectile (chama super)
	super(delta)


## Aplica squash/stretch no sprite: quando vira, estica na direção do movimento
## (longo + fino) pra dar feel de "curvou bruscamente". Quando vai reto, retorna.
func _apply_smear(delta: float, turn_intensity: float) -> void:
	if _sprite == null:
		return
	# Quanto mais virou, mais stretch horizontal e mais squash vertical.
	# stretch base 1.0, sobe até 2.0 quando virando 100%.
	var target_stretch_x: float = 1.0 + turn_intensity * 1.0
	var target_squash_y: float = 1.0 - turn_intensity * 0.4
	# Lerp suave pra animação ficar fluida (não snappy).
	var base_scale := Projectile.SPRITE_SCALE
	_sprite.scale = _sprite.scale.lerp(
		Vector2(base_scale * target_stretch_x, base_scale * target_squash_y),
		delta * 12.0
	)


func _find_target() -> Enemy:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Enemy = null
	var nearest_d: float = seek_radius
	for e in enemies:
		if not (e is Enemy):
			continue
		if (e as Enemy)._dying_anim:
			continue
		var d: float = global_position.distance_to((e as Enemy).global_position)
		if d < nearest_d:
			nearest_d = d
			nearest = e
	return nearest
