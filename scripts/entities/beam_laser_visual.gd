## Visual do beam laser — linha brilhante entre dois pontos com glow.
## Atualizado a cada frame pelo cartridge.
class_name BeamLaserVisual
extends Node2D

var color: Color = Color.WHITE
var width: float = 6.0
var target_visible: bool = false
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _pulse: float = 0.0


func _ready() -> void:
	z_index = 4


func set_endpoints(p_from: Vector2, p_to: Vector2) -> void:
	_from = p_from
	_to = p_to


func _process(delta: float) -> void:
	_pulse += delta * 12.0
	queue_redraw()


func _draw() -> void:
	if not target_visible:
		return
	var pulse_v: float = 0.85 + 0.15 * sin(_pulse)
	# Glow externo (largura maior, alpha menor)
	var glow_col := Color(color.r, color.g, color.b, 0.25 * pulse_v)
	draw_line(_from, _to, glow_col, width * 2.5)
	# Beam core (full color, largura nominal)
	var core_col := Color(color.r, color.g, color.b, 0.9 * pulse_v)
	draw_line(_from, _to, core_col, width)
	# Hot center (branco brilhante, largura pequena)
	var hot_col := Color(1.0, 1.0, 1.0, 0.85 * pulse_v)
	draw_line(_from, _to, hot_col, width * 0.4)
