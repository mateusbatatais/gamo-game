## Projétil que sai do player, atinge alcance máximo, desacelera e retorna.
## Atravessa inimigos (pierce infinito), mas só dá hit no MESMO inimigo uma vez
## na ida e uma vez na volta (não múltiplos ticks).
class_name BoomerangProjectile
extends Projectile

const PHASE_OUT_DURATION := 0.55
const RETURN_SPEED := 220.0

var _owner_player: Player = null
var _phase_out_age: float = 0.0
var _returning: bool = false
var _initial_speed: float = 280.0
var _hits_outbound: Array = []
var _hits_return: Array = []


func setup_boomerang(p_player: Player, dir: Vector2, p_damage: int) -> void:
	_owner_player = p_player
	# Pierce alto pra atravessar — boomerang acerta vários no caminho.
	setup(p_player.global_position, dir, p_damage, _initial_speed, 99)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if not _returning:
		_phase_out_age += delta
		# Desacelera linearmente até parar.
		var t: float = clampf(_phase_out_age / PHASE_OUT_DURATION, 0.0, 1.0)
		speed = lerpf(_initial_speed, 0.0, t)
		if t >= 1.0:
			_returning = true
			_hits_outbound.clear()  # reseta lista pra permitir hits na volta
		position += direction * speed * delta
	else:
		# Retorna em direção ao player.
		if _owner_player == null or not is_instance_valid(_owner_player):
			queue_free()
			return
		var to_player: Vector2 = _owner_player.global_position - global_position
		if to_player.length() < 14.0:
			# Voltou — desaparece.
			queue_free()
			return
		direction = to_player.normalized()
		position += direction * RETURN_SPEED * delta
		rotation = direction.angle()
	_age += delta
	if _age >= 4.0:
		queue_free()


## Override pra usar duas listas (ida e volta).
func _on_body_entered(body: Node2D) -> void:
	if not (body is Enemy):
		return
	var hits_list: Array = _hits_return if _returning else _hits_outbound
	if body in hits_list:
		return
	hits_list.append(body)
	var is_crit: bool = randf() < crit_chance
	var final_dmg: int = int(round(float(damage) * (crit_mult if is_crit else 1.0)))
	(body as Enemy).take_damage(final_dmg, Vector2.ZERO, is_crit)
	Audio.play(Audio.Sfx.HIT)
