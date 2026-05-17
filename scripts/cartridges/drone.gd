## Drone — companheiro autônomo que orbita o player e atira em inimigos próximos.
## Level escala: rate of fire + damage + número de drones (cap 3).
extends CartridgeBase

const BASE_INTERVAL := 0.9
const BASE_DAMAGE := 6
const ORBIT_RADIUS := 28.0
const ORBIT_SPEED := 1.8  ## rad/s
const SEARCH_RADIUS := 220.0
const TINT := Color("#90caf9")

var _drones: Array[Node2D] = []
var _angle: float = 0.0
var _fire_timer: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	p_player.set_weapon_visual(Sprites.weapon_orbital, TINT)
	_rebuild_drones()


func on_level_up(new_level: int) -> void:
	super(new_level)
	_rebuild_drones()


func on_unequip() -> void:
	for d in _drones:
		if is_instance_valid(d):
			d.queue_free()
	_drones.clear()


func _drone_count() -> int:
	# nv1 = 1, nv3 = 2, nv5 = 3
	return clampi((level + 1) / 2, 1, 3)


func _damage() -> int:
	return int(roundf((BASE_DAMAGE + (level - 1) * 2) * player.damage_mult))


func _interval() -> float:
	return BASE_INTERVAL * pow(0.9, level - 1)


func _rebuild_drones() -> void:
	for d in _drones:
		if is_instance_valid(d):
			d.queue_free()
	_drones.clear()
	if player == null:
		return
	for i in _drone_count():
		var d := Node2D.new()
		var sprite := Sprite2D.new()
		sprite.texture = Sprites.weapon_orbital
		sprite.centered = true
		sprite.scale = Vector2(1.4, 1.4)
		sprite.modulate = TINT
		d.add_child(sprite)
		player.add_child(d)
		_drones.append(d)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	# Roda em formação ao redor do player.
	_angle += ORBIT_SPEED * delta
	var n := _drones.size()
	for i in n:
		var d := _drones[i]
		if not is_instance_valid(d):
			continue
		var a: float = _angle + TAU * float(i) / float(n)
		d.position = Vector2(cos(a), sin(a)) * ORBIT_RADIUS
	# Fire timer
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = _interval()
		_fire_from_drones()


func _fire_from_drones() -> void:
	for d in _drones:
		if not is_instance_valid(d):
			continue
		# Cada drone procura um alvo na sua área.
		var target := player.find_nearest_enemy(SEARCH_RADIUS)
		if target == null:
			continue
		var origin: Vector2 = d.global_position
		var dir := (target.global_position - origin).normalized()
		var proj := Projectile.new()
		proj.tint = TINT
		proj.crit_chance = player.crit_chance
		proj.crit_mult = player.crit_mult
		proj.setup(origin, dir, _damage(), 260.0, 0)
		player.get_parent().add_child(proj)
	Audio.play(Audio.Sfx.SHOOT)
