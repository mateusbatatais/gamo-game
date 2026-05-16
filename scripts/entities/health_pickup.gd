## Pickup de vida (coração vermelho). Restaura HEAL_PERCENT do max HP do player.
## Spawnado ocasionalmente por inimigos abatidos.
class_name HealthPickup
extends Area2D

const ATTRACT_SPEED := 220.0
const TOUCH_DISTANCE := 10.0
const ATTRACT_RADIUS := 56.0
const SPRITE_SCALE := 2.0
const HEAL_PERCENT := 0.20

var _sprite: Sprite2D
var _bob_phase: float = 0.0


func _ready() -> void:
	collision_layer = 32  # pickup
	collision_mask = 0
	monitorable = true
	monitoring = false
	_bob_phase = randf() * TAU
	_build_shape()
	_build_visual()


func _build_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)


func _build_visual() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = Sprites.health_pickup
	_sprite.centered = true
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	add_child(_sprite)


func _process(delta: float) -> void:
	_bob_phase += delta * 4.0
	if _sprite != null:
		_sprite.position.y = sin(_bob_phase) * 1.5

	var player := _find_player()
	if player == null:
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist <= TOUCH_DISTANCE:
		_collect(player)
		return
	var radius: float = ATTRACT_RADIUS * player.pickup_radius_mult
	if dist <= radius:
		global_position += to_player.normalized() * ATTRACT_SPEED * delta


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player


func _collect(player: Player) -> void:
	var heal_amount: int = max(1, int(round(float(player.max_hp) * HEAL_PERCENT)))
	player.heal(heal_amount)
	Audio.play(Audio.Sfx.PICKUP)
	queue_free()
