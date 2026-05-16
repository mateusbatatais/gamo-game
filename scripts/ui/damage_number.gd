## Número flutuante que sobe quando um inimigo toma dano.
## Cor e tamanho variam pra dano normal vs crítico.
class_name DamageNumber
extends Node2D

const LIFETIME := 0.7
const RISE_DISTANCE := 28.0
const HORIZONTAL_DRIFT := 14.0
const NORMAL_COLOR := Color("#ffffff")
const CRIT_COLOR := Color("#ffeb3b")

var _age: float = 0.0
var _label: Label
var _drift_x: float = 0.0


func setup(amount: int, is_crit: bool = false) -> void:
	_label = Label.new()
	_label.text = str(amount)
	var font_size: int = 12
	var col: Color = NORMAL_COLOR
	if is_crit:
		_label.text += "!"
		font_size = 18
		col = CRIT_COLOR
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", col)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	_label.pivot_offset = Vector2(20, 8)
	# Centraliza horizontalmente o texto sobre a posição do nó.
	_label.position = Vector2(-20, -8)
	_label.size = Vector2(40, 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drift_x = randf_range(-HORIZONTAL_DRIFT, HORIZONTAL_DRIFT)
	add_child(_label)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var t: float = _age / LIFETIME
	# Sobe com easing out — começa rápido, desacelera
	var rise: float = RISE_DISTANCE * (1.0 - pow(1.0 - t, 2.0))
	position.y = -rise
	position.x = _drift_x * t
	# Fade out na segunda metade
	var alpha: float = 1.0 if t < 0.55 else clampf((1.0 - t) / 0.45, 0.0, 1.0)
	if _label != null:
		_label.modulate.a = alpha
		# Crits têm pulso de scale no início
		if _age < 0.18:
			var pulse: float = 1.0 + (1.0 - _age / 0.18) * 0.5
			_label.scale = Vector2(pulse, pulse)
		else:
			_label.scale = Vector2.ONE
