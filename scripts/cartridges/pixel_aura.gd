## Pixel Aura — pixels orbitam o jogador causando dano contínuo.
extends CartridgeBase

const ORBIT_RADIUS := 36.0
const ORBIT_SPEED := 3.0  # rad/s
const TICK_DAMAGE_INTERVAL := 0.25
const BASE_DAMAGE := 3
const SPRITE_SCALE := 2.0

const TINT := Color("#00e5ff")  # ciano orbital

var _orbiters: Array[Area2D] = []
var _angle: float = 0.0
var _tick_timer: float = 0.0
var _hit_log: Dictionary = {}  # enemy -> last hit time


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	p_player.set_weapon_visual(Sprites.weapon_orbital, TINT)
	_rebuild()


func on_level_up(new_level: int) -> void:
	super(new_level)
	_rebuild()


func _orbiter_count() -> int:
	return 2 + (level - 1)  # 2 -> 6


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1)) * player.damage_mult))


func on_unequip() -> void:
	for o in _orbiters:
		if is_instance_valid(o):
			o.queue_free()
	_orbiters.clear()


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
		circle.radius = 6.0
		shape.shape = circle
		orb.add_child(shape)
		var sprite := Sprite2D.new()
		sprite.texture = Sprites.projectile
		sprite.centered = true
		sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		orb.add_child(sprite)
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
		var a := _angle + step * float(i)
		orb.position = Vector2(cos(a), sin(a)) * ORBIT_RADIUS

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
			if body is Enemy:
				var roll: Array = player.roll_damage(dmg)
				(body as Enemy).take_damage(roll[0], Vector2.ZERO, roll[1])
