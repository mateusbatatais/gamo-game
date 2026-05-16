## Chaos Field — evolução de Pixel Aura + Spread Cart.
## Orbitais ao redor do player + periodicamente disparam projeteis radiais.
extends CartridgeBase

const ORBIT_RADIUS := 40.0
const ORBIT_SPEED := 3.5
const TICK_DAMAGE_INTERVAL := 0.22
const BASE_DAMAGE := 5
const PULSE_INTERVAL := 1.6
const PULSE_PROJECTILES := 8
const PULSE_DAMAGE := 7
const PULSE_SPEED := 180.0
const SPRITE_SCALE := 2.0

const TINT := Color("#e040fb")  # magenta caótico

var _orbiters: Array[Area2D] = []
var _angle: float = 0.0
var _tick_timer: float = 0.0
var _pulse_timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	p_player.set_weapon_visual(Sprites.weapon_orbital, TINT)
	_rebuild()


func on_level_up(new_level: int) -> void:
	super(new_level)
	_rebuild()


func _orbiter_count() -> int:
	return 4 + (level - 1)


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 2) * player.damage_mult))


func _pulse_damage() -> int:
	return int(roundf((PULSE_DAMAGE + (level - 1) * 3) * player.damage_mult))


func _rebuild() -> void:
	for o in _orbiters:
		if is_instance_valid(o):
			o.queue_free()
	_orbiters.clear()
	if player == null:
		return
	for i in _orbiter_count():
		var orb := Area2D.new()
		orb.collision_layer = 64
		orb.collision_mask = 8
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 7.0
		shape.shape = circle
		orb.add_child(shape)
		var sprite := Sprite2D.new()
		sprite.texture = Sprites.projectile
		sprite.centered = true
		sprite.scale = Vector2(SPRITE_SCALE * 1.2, SPRITE_SCALE * 1.2)
		sprite.modulate = Color("#e040fb")
		orb.add_child(sprite)
		player.add_child(orb)
		_orbiters.append(orb)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_angle += ORBIT_SPEED * delta
	var count := _orbiters.size()
	if count > 0:
		var step: float = TAU / float(count)
		for i in count:
			var orb := _orbiters[i]
			if not is_instance_valid(orb):
				continue
			var a: float = _angle + step * float(i)
			orb.position = Vector2(cos(a), sin(a)) * ORBIT_RADIUS

	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = TICK_DAMAGE_INTERVAL
		_apply_orbit_damage()

	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		_pulse_timer = PULSE_INTERVAL * pow(0.95, level - 1)
		_fire_pulse()


func _apply_orbit_damage() -> void:
	var dmg := _damage()
	for orb in _orbiters:
		if not is_instance_valid(orb):
			continue
		for body in orb.get_overlapping_bodies():
			if body is Enemy:
				var roll: Array = player.roll_damage(dmg)
				(body as Enemy).take_damage(roll[0], Vector2.ZERO, roll[1])


func _fire_pulse() -> void:
	var count: int = PULSE_PROJECTILES + (level - 1) * 2
	var dmg := _pulse_damage()
	for i in count:
		var angle: float = TAU * float(i) / float(count)
		var dir := Vector2(cos(angle), sin(angle))
		var proj := Projectile.new()
		proj.tint = TINT
		proj.crit_chance = player.crit_chance
		proj.crit_mult = player.crit_mult
		proj.setup(player.global_position, dir, dmg, PULSE_SPEED, 1)
		player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
