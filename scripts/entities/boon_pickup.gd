## Pickup de Boon — orbe pulsante que concede um buff temporário ao player.
## Dropado por mini-bosses. Sprite procedural circular com ring duplo + cor da kind.
class_name BoonPickup
extends Area2D

const TOUCH_DISTANCE := 12.0
const ATTRACT_RADIUS := 70.0
const ATTRACT_SPEED := 200.0
const SPRITE_SCALE := 2.0

@export var kind: int = BoonSystem.Kind.DOUBLE_SHOT

var _sprite: Sprite2D
var _bob_phase: float = 0.0
var _glow_phase: float = 0.0


func _ready() -> void:
	collision_layer = 32
	collision_mask = 0
	monitorable = true
	monitoring = false
	_bob_phase = randf() * TAU
	_build_shape()
	_build_visual()


func _build_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)


func _build_visual() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _make_orb_texture()
	_sprite.centered = true
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	add_child(_sprite)


## Gera um orbe procedural 10x10 com a cor do boon ao centro + ring branco.
func _make_orb_texture() -> ImageTexture:
	var c: Color = BoonSystem.COLORS[kind]
	var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	var center := Vector2(4.5, 4.5)
	for y in 10:
		for x in 10:
			var d: float = Vector2(x, y).distance_to(center)
			if d <= 1.6:
				img.set_pixel(x, y, Color.WHITE)  # core branco
			elif d <= 3.2:
				img.set_pixel(x, y, c)            # cor do boon
			elif d <= 4.0:
				img.set_pixel(x, y, Color(c.r * 0.5, c.g * 0.5, c.b * 0.5))  # borda escura
			elif d <= 4.6:
				img.set_pixel(x, y, Color.WHITE)  # ring externo
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_bob_phase += delta * 4.0
	_glow_phase += delta * 3.0
	if _sprite != null:
		_sprite.position.y = sin(_bob_phase) * 3.0
		var brightness: float = 1.0 + 0.5 * sin(_glow_phase)
		_sprite.modulate = Color(brightness, brightness, brightness, 1.0)
	var player := _find_player()
	if player == null:
		return
	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	if dist <= TOUCH_DISTANCE:
		_collect()
		return
	var radius: float = ATTRACT_RADIUS * player.pickup_radius_mult
	if dist <= radius:
		global_position += to_player.normalized() * ATTRACT_SPEED * delta


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player


func _collect() -> void:
	BoonSystem.grant(kind)
	Audio.play(Audio.Sfx.UI_CONFIRM)
	queue_free()
