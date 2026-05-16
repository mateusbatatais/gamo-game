## Vinheta vermelha pulsante que aparece nas bordas da tela quando o HP está baixo.
## Quanto mais perto do 0, mais intensa e rápida a pulsação.
class_name HpVignette
extends Control

const FADE_THRESHOLD := 0.40   # começa a aparecer abaixo de 40% HP
const MAX_ALPHA := 0.65
const PULSE_BASE_SPEED := 3.0
const PULSE_MAX_SPEED := 7.0

var _hp_ratio: float = 1.0
var _pulse_phase: float = 0.0
var _texture: TextureRect


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_texture()
	EventBus.player_damaged.connect(_on_hp_changed)
	EventBus.player_healed.connect(_on_hp_changed)
	EventBus.run_started.connect(_on_run_started)


func _build_texture() -> void:
	# Gera imagem 80x45 (proporção do viewport 640x360) com gradiente radial
	# transparente no centro → vermelho profundo nas bordas.
	var w := 80
	var h := 45
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx := float(w) * 0.5 - 0.5
	var cy := float(h) * 0.5 - 0.5
	var max_d := sqrt(cx * cx + cy * cy)
	for y in h:
		for x in w:
			var dx := float(x) - cx
			var dy := float(y) - cy
			var d: float = sqrt(dx * dx + dy * dy) / max_d
			# Curva acentuada — centro transparente, borda vermelho intenso
			var a: float = clampf(pow(d, 2.5), 0.0, 1.0)
			img.set_pixel(x, y, Color(0.95, 0.05, 0.05, a))
	var tex := ImageTexture.create_from_image(img)
	_texture = TextureRect.new()
	_texture.texture = tex
	_texture.anchor_right = 1.0
	_texture.anchor_bottom = 1.0
	_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture.stretch_mode = TextureRect.STRETCH_SCALE
	_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture.modulate.a = 0.0
	add_child(_texture)


func _on_hp_changed(_amount: int, current: int, maximum: int) -> void:
	_hp_ratio = float(current) / float(maximum) if maximum > 0 else 1.0


func _on_run_started() -> void:
	_hp_ratio = 1.0
	if _texture != null:
		_texture.modulate.a = 0.0


func _process(delta: float) -> void:
	if _texture == null:
		return
	if _hp_ratio >= FADE_THRESHOLD:
		_texture.modulate.a = 0.0
		return
	var danger: float = 1.0 - (_hp_ratio / FADE_THRESHOLD)
	var pulse_speed: float = lerpf(PULSE_BASE_SPEED, PULSE_MAX_SPEED, danger)
	_pulse_phase += delta * pulse_speed
	var pulse: float = 0.55 + 0.45 * sin(_pulse_phase)
	_texture.modulate.a = MAX_ALPHA * danger * pulse
