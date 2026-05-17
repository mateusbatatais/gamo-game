## Reflector — escudos orbitais que destroem projéteis inimigos ao tocá-los
## e dão pequeno dano a inimigos que entram no orbital. 1 escudo no level 1,
## +1 por nível até 5.
extends CartridgeBase

const ORBIT_RADIUS := 38.0
const ORBIT_SPEED := 3.2
const BASE_DAMAGE := 3
const TICK_DAMAGE_INTERVAL := 0.4
const TINT := Color("#90caf9")
const SPRITE_SCALE := 2.0

var _orbiters: Array[Area2D] = []
var _angle: float = 0.0
var _tick_timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	p_player.set_weapon_visual(Sprites.weapon_orbital, TINT)
	_rebuild()


func on_level_up(new_level: int) -> void:
	super(new_level)
	_rebuild()


func on_unequip() -> void:
	for o in _orbiters:
		if is_instance_valid(o):
			o.queue_free()
	_orbiters.clear()


func _shield_count() -> int:
	return 1 + (level - 1)  # 1, 2, 3, 4, 5


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 2) * player.damage_mult))


func _rebuild() -> void:
	for o in _orbiters:
		if is_instance_valid(o):
			o.queue_free()
	_orbiters.clear()
	if player == null:
		return
	for i in _shield_count():
		var orb := Area2D.new()
		# Layer 64 = projectile_player (também atinge inimigos).
		# Mask 128 + 8 = projétil inimigo + corpo de inimigo.
		orb.collision_layer = 64
		orb.collision_mask = 128 + 8
		orb.monitoring = true
		orb.monitorable = true
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		shape.shape = circle
		orb.add_child(shape)
		var sprite := Sprite2D.new()
		sprite.texture = Sprites.weapon_orbital
		sprite.centered = true
		sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE) * 0.8
		sprite.modulate = TINT
		orb.add_child(sprite)
		# Conecta os hits.
		orb.area_entered.connect(_on_area_entered)
		player.add_child(orb)
		_orbiters.append(orb)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_angle += ORBIT_SPEED * delta
	var count := _orbiters.size()
	if count == 0:
		return
	var step: float = TAU / float(count)
	for i in count:
		var orb := _orbiters[i]
		if not is_instance_valid(orb):
			continue
		var a: float = _angle + step * float(i)
		orb.position = Vector2(cos(a), sin(a)) * ORBIT_RADIUS
	# Dano periódico em inimigos sobrepostos.
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = TICK_DAMAGE_INTERVAL
		_apply_damage()


func _apply_damage() -> void:
	var dmg := _damage()
	for orb in _orbiters:
		if not is_instance_valid(orb):
			continue
		for body in orb.get_overlapping_bodies():
			if body is Enemy and not (body as Enemy)._dying_anim:
				var roll: Array = player.roll_damage(dmg)
				(body as Enemy).take_damage(roll[0], Vector2.ZERO, roll[1])


## Quando um projétil inimigo bate no orbital: destrói o projétil
## (reflexão "passiva" — não retorna, só anula).
func _on_area_entered(area: Area2D) -> void:
	if area is EnemyProjectile:
		area.queue_free()
		Audio.play(Audio.Sfx.HIT)
