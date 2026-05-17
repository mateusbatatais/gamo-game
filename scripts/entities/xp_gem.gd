## Gema de XP dropada por inimigos.
## É atraída pelo player quando dentro do raio de pickup, e some ao tocar.
class_name XpGem
extends Area2D

const ATTRACT_SPEED := 180.0
const TOUCH_DISTANCE := 8.0
const BASE_ATTRACT_RADIUS := 40.0
const SPRITE_SCALE := 2.0

@export var value: int = 1

var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 32  # pickup
	collision_mask = 0
	monitorable = true
	monitoring = false
	_build_shape()
	_build_visual()


func _build_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)


func _build_visual() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = Sprites.make_animation(
		Sprites.XP_GEM, Sprites.PALETTE_GEM, 6.0
	)
	_sprite.centered = true
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.play("default")
	# Glow azul-ciano pra chamar atenção pra coleta de XP.
	var glow_shader: Shader = load("res://shaders/glow.gdshader")
	if glow_shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = glow_shader
		mat.set_shader_parameter("glow_strength", 2.0)
		mat.set_shader_parameter("glow_radius", 2.5)
		mat.set_shader_parameter("glow_tint", Color("#00e5ff"))
		mat.set_shader_parameter("threshold", 0.3)
		_sprite.material = mat
	add_child(_sprite)


func _process(delta: float) -> void:
	var player := _find_player()
	if player == null:
		return
	var attract_radius := BASE_ATTRACT_RADIUS * player.pickup_radius_mult
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist <= TOUCH_DISTANCE:
		_collect(player)
		return
	if dist <= attract_radius:
		var t := 1.0 - (dist / attract_radius)
		var speed := ATTRACT_SPEED * (0.5 + t * 1.5)
		global_position += to_player.normalized() * speed * delta


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player


func _collect(player: Player) -> void:
	XpSystem.add_xp(value)
	Audio.play(Audio.Sfx.PICKUP)
	queue_free()
