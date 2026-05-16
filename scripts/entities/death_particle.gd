## Explosão pixelada ao matar um inimigo. Spawna N quadradinhos voando em
## direções aleatórias, com decay e fade-out. Auto-libera após LIFETIME.
class_name DeathParticle
extends Node2D

const LIFETIME := 0.5
const PARTICLE_COUNT := 10
const SPEED_MIN := 60.0
const SPEED_MAX := 160.0
const SIZE := 3.0
const FRICTION := 0.88

var _age: float = 0.0
var _positions: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _color: Color = Color.WHITE


## Configura a explosão com a cor base do inimigo abatido.
func setup(p_color: Color) -> void:
	_color = p_color
	for i in PARTICLE_COUNT:
		_positions.append(Vector2.ZERO)
		var angle: float = (TAU * float(i) / float(PARTICLE_COUNT)) + randf_range(-0.35, 0.35)
		var speed: float = randf_range(SPEED_MIN, SPEED_MAX)
		_velocities.append(Vector2(cos(angle), sin(angle)) * speed)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	for i in _positions.size():
		_positions[i] += _velocities[i] * delta
		_velocities[i] *= FRICTION
	queue_redraw()


func _draw() -> void:
	var t: float = 1.0 - (_age / LIFETIME)
	var col := Color(_color.r, _color.g, _color.b, t)
	var half := Vector2(SIZE * 0.5, SIZE * 0.5)
	for pos in _positions:
		draw_rect(Rect2(pos - half, Vector2(SIZE, SIZE)), col, true)
