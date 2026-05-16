## Power-up raro dropado por inimigos comuns (chance baixa) e mini-bosses (garantido).
## Três tipos: FREEZE (congela inimigos), NUKE (mata tudo na tela), MAGNET (atrai todas as gemas).
## Ao tocar no player emite EventBus.power_up_collected — a Arena resolve o efeito.
class_name PowerUp
extends Area2D

enum Kind { FREEZE, NUKE, MAGNET }

const SPRITE_SCALE := 2.0
const TOUCH_DISTANCE := 12.0

@export var kind: int = Kind.FREEZE

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
	_sprite.texture = _texture_for_kind(kind)
	_sprite.centered = true
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	add_child(_sprite)


func _texture_for_kind(k: int) -> ImageTexture:
	match k:
		Kind.FREEZE:
			return Sprites.powerup_freeze
		Kind.NUKE:
			return Sprites.powerup_nuke
		Kind.MAGNET:
			return Sprites.powerup_magnet
	return Sprites.powerup_freeze


func _process(delta: float) -> void:
	_bob_phase += delta * 4.5
	_glow_phase += delta * 3.0
	if _sprite != null:
		_sprite.position.y = sin(_bob_phase) * 2.5
		# Pulso de modulate pra dar aura de "raro"
		var brightness: float = 1.0 + 0.4 * sin(_glow_phase)
		_sprite.modulate = Color(brightness, brightness, brightness, 1.0)

	var player := _find_player()
	if player == null:
		return
	if global_position.distance_to(player.global_position) <= TOUCH_DISTANCE:
		_collect()


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player


func _collect() -> void:
	Audio.play(Audio.Sfx.LEVEL_UP)  # som especial pra power-up (reusando o de up de nível)
	EventBus.power_up_collected.emit(kind)
	queue_free()
