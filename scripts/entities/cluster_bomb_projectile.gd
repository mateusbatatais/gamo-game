## Projétil que voa um tempo, então explode em N estilhaços em padrão estrela.
## Causa dano da casca em quem acertar antes de detonar.
class_name ClusterBombProjectile
extends Projectile

var fuse_time: float = 0.55
var fragment_count: int = 6
var shrapnel_speed: float = 200.0
var shrapnel_damage: int = 6
var _exploded: bool = false


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	# Detona quando o fuse expira (substitui o lifetime padrão).
	_age += delta
	if _age >= fuse_time:
		_detonate()
		return
	position += direction * speed * delta
	if not _inside_play_area():
		_detonate()


## Hit na casca: aplica dano normal + detona se ainda não detonou.
func _on_body_entered(body: Node2D) -> void:
	if _exploded:
		return
	if body in _hits:
		return
	if not (body is Enemy):
		return
	_hits.append(body)
	var is_crit: bool = randf() < crit_chance
	var final_dmg: int = int(round(float(damage) * (crit_mult if is_crit else 1.0)))
	(body as Enemy).take_damage(final_dmg, Vector2.ZERO, is_crit)
	Audio.play(Audio.Sfx.HIT)
	_detonate()


func _detonate() -> void:
	if _exploded:
		return
	_exploded = true
	# Spawna N estilhaços em padrão estrela.
	for i in fragment_count:
		var angle: float = TAU * float(i) / float(fragment_count)
		var dir := Vector2.RIGHT.rotated(angle)
		var frag := Projectile.new()
		frag.tint = tint
		frag.crit_chance = crit_chance
		frag.crit_mult = crit_mult
		frag.setup(global_position, dir, shrapnel_damage, shrapnel_speed, 0)
		get_parent().add_child(frag)
	Audio.play(Audio.Sfx.HIT)
	queue_free()
