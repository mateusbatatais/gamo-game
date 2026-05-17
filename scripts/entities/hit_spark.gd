## Spark de impacto quando projétil acerta inimigo. Pequena explosão radial
## de pontos brilhantes que rapidamente fadem. Dá impacto visual a cada hit
## sem custar performance (8 partículas por hit, vida 0.25s).
class_name HitSpark
extends Node2D

const PARTICLE_COUNT := 8
const LIFETIME := 0.28
const BASE_SPEED := 80.0
const SPEED_VARIANCE := 40.0

var _age: float = 0.0
var _particles: Array[Vector2] = []  ## posições
var _velocities: Array[Vector2] = []
var _color: Color = Color.WHITE


func setup(p_position: Vector2, p_color: Color) -> void:
	global_position = p_position
	_color = p_color
	z_index = 5
	for i in PARTICLE_COUNT:
		var angle: float = TAU * float(i) / float(PARTICLE_COUNT) + randf_range(-0.2, 0.2)
		var speed: float = BASE_SPEED + randf_range(-SPEED_VARIANCE, SPEED_VARIANCE)
		_particles.append(Vector2.ZERO)
		_velocities.append(Vector2(cos(angle), sin(angle)) * speed)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	for i in _particles.size():
		_particles[i] += _velocities[i] * delta
		# Desacelera rapidamente
		_velocities[i] *= 0.88
	queue_redraw()


func _draw() -> void:
	var t: float = _age / LIFETIME
	# Fade-out + leve shrink dos pontos
	var alpha: float = clampf(1.0 - t, 0.0, 1.0)
	var size: float = lerpf(2.5, 0.5, t)
	for p in _particles:
		var col := Color(_color.r, _color.g, _color.b, alpha)
		# Contorno branco interno pra "spark" — núcleo brilhante.
		draw_rect(Rect2(p - Vector2(size, size) * 0.5, Vector2(size, size)), col, true)
		if t < 0.4:
			var inner := Color(1.0, 1.0, 1.0, alpha * 0.7)
			draw_rect(
				Rect2(p - Vector2(size, size) * 0.3, Vector2(size, size) * 0.6),
				inner, true
			)
