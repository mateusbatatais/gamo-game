## Intro dramática do boss: pausa o jogo, escurece a tela, mostra title card
## escorregando + zoom-in na câmera, depois libera pra luta começar.
## Roda com PROCESS_MODE_ALWAYS porque a árvore fica pausada durante a intro.
class_name BossIntro
extends CanvasLayer

signal finished

const DURATION := 2.4
const ZOOM_IN_TIME := 0.6
const HOLD_TIME := 1.4
const ZOOM_OUT_TIME := 0.4
const TARGET_ZOOM := 1.6

var _age: float = 0.0
var _ended: bool = false
var _bg: ColorRect
var _title: Label
var _subtitle: TypewriterLabel
var _subtitle_typed: bool = false
var _camera: Camera2D
var _camera_focus: Vector2 = Vector2.ZERO
var _initial_zoom: Vector2 = Vector2.ONE


func _ready() -> void:
	layer = 8  # entre HUD (5) e modal de level-up (10)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.0)
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 64)
	_title.add_theme_color_override("font_color", Color("#ff5252"))
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 8)
	_title.anchor_left = 0.5
	_title.anchor_right = 0.5
	_title.anchor_top = 0.5
	_title.anchor_bottom = 0.5
	_title.position = Vector2(-320, -56)
	_title.size = Vector2(640, 80)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.pivot_offset = Vector2(320, 40)
	add_child(_title)

	# Subtítulo typewriter — escreve char por char com beep.
	var tw := TypewriterLabel.new()
	tw.add_theme_font_size_override("font_size", 16)
	tw.add_theme_color_override("font_color", Color("#ffeb3b"))
	tw.add_theme_color_override("font_outline_color", Color.BLACK)
	tw.add_theme_constant_override("outline_size", 3)
	tw.anchor_left = 0.5
	tw.anchor_right = 0.5
	tw.anchor_top = 0.5
	tw.anchor_bottom = 0.5
	tw.position = Vector2(-200, 28)
	tw.size = Vector2(400, 22)
	tw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tw.modulate.a = 0.0
	add_child(tw)
	_subtitle = tw


## Configura a intro com o nome do boss, posição alvo da câmera (zoom-in) e
## a Camera2D que será manipulada pra dar o efeito de zoom.
func start(boss_name: String, target_pos: Vector2, camera: Camera2D) -> void:
	_title.text = boss_name.to_upper()
	_title.scale = Vector2(2.4, 2.4)  # começa grande, encolhe pra dar impacto
	_title.modulate = Color(1, 1, 1, 0)
	_camera = camera
	_camera_focus = target_pos
	if _camera != null:
		_initial_zoom = _camera.zoom


func _process(delta: float) -> void:
	if _ended:
		return
	_age += delta

	# Fundo escurece rapidamente
	_bg.color.a = clampf(_age / 0.3, 0.0, 0.55)

	# Fase de zoom-in da câmera + zoom do título descendo de 2.4 → 1.0
	if _age <= ZOOM_IN_TIME:
		var t: float = _age / ZOOM_IN_TIME
		var eased: float = _ease_out_cubic(t)
		if _camera != null:
			_camera.zoom = _initial_zoom.lerp(Vector2(TARGET_ZOOM, TARGET_ZOOM), eased)
			_camera.offset = _camera_offset_for_focus() * eased
		var title_scale: float = lerpf(2.4, 1.0, eased)
		_title.scale = Vector2(title_scale, title_scale)
		_title.modulate.a = clampf(t * 1.5, 0.0, 1.0)
	elif _age <= ZOOM_IN_TIME + HOLD_TIME:
		# Hold com leve wobble + subtitle aparece com typewriter.
		var hold_t: float = (_age - ZOOM_IN_TIME) / HOLD_TIME
		var wobble: float = 1.0 + sin(hold_t * 18.0) * 0.04
		_title.scale = Vector2(wobble, wobble)
		_subtitle.modulate.a = clampf(hold_t * 2.5, 0.0, 1.0)
		if not _subtitle_typed:
			_subtitle_typed = true
			_subtitle.type_text("- CHEFE FINAL -", 0.05)
	else:
		# Zoom-out: câmera volta + título e bg saem
		var out_t: float = (_age - ZOOM_IN_TIME - HOLD_TIME) / ZOOM_OUT_TIME
		var eased_out: float = _ease_in_cubic(out_t)
		if _camera != null:
			_camera.zoom = Vector2(TARGET_ZOOM, TARGET_ZOOM).lerp(_initial_zoom, eased_out)
			_camera.offset = _camera_offset_for_focus() * (1.0 - eased_out)
		_title.modulate.a = clampf(1.0 - out_t, 0.0, 1.0)
		_subtitle.modulate.a = clampf(1.0 - out_t, 0.0, 1.0)
		_bg.color.a = lerpf(0.55, 0.0, eased_out)

	if _age >= DURATION:
		_ended = true
		if _camera != null:
			_camera.zoom = _initial_zoom
			_camera.offset = Vector2.ZERO
		finished.emit()


## Camera2D em viewport stretch: pra "centrar" no boss precisamos calcular
## o offset relativo ao centro da arena (que é a posição base da câmera).
func _camera_offset_for_focus() -> Vector2:
	if _camera == null:
		return Vector2.ZERO
	# Aplica metade do offset pra não sair do enquadramento (mantém boss visível
	# mas câmera ainda quase centralizada).
	return (_camera_focus - _camera.position) * 0.4


func _ease_out_cubic(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


func _ease_in_cubic(x: float) -> float:
	return x * x * x
