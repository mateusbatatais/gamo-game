## Mini-puzzle entre fases — "Restaure o Cartucho Corrompido".
##
## Fluxo:
##   1. INTRO       — explica as regras, espera ENTER/ESPAÇO pra começar (ou ESC pra pular)
##   2. SHOWING     — mostra sequência de 4 setas com pausa visível entre cada
##   3. INPUT       — player reproduz; indicador mostra progresso
##   4. DONE        — resultado por 1.5s e fecha
##
## Layer 11 + PROCESS_MODE_ALWAYS — funciona mesmo com gameplay pausado.
## Sucesso = cura total + 80 tokens. Skip/erro = sem punição.
class_name CartridgePuzzle
extends CanvasLayer

signal completed(success: bool)

const SEQUENCE_LENGTH := 4
const SHOW_FLASH_TIME := 0.55  ## quanto tempo cada seta fica acesa
const SHOW_GAP_TIME := 0.30    ## pausa entre setas (player precisa ver separação)
const PANEL_WIDTH := 480
const PANEL_HEIGHT := 320

enum Direction { UP, LEFT, DOWN, RIGHT }
const DIR_COLORS := {
	Direction.UP: Color("#9bbc0f"),
	Direction.LEFT: Color("#00e5ff"),
	Direction.DOWN: Color("#ff9800"),
	Direction.RIGHT: Color("#e040fb"),
}
const DIR_ACTIONS := {
	Direction.UP: "move_up",
	Direction.LEFT: "move_left",
	Direction.DOWN: "move_down",
	Direction.RIGHT: "move_right",
}

enum State { INTRO, SHOWING, GAP, INPUT, DONE }

var _state: int = State.INTRO
var _sequence: Array[int] = []
var _player_index: int = 0
var _show_index: int = 0
var _state_timer: float = 0.0
var _flash_remaining: float = 0.0
var _flashed_dir: int = -1
var _root: Control
var _arrow_rects: Dictionary = {}  ## Direction → wrap Control
var _instructions: Label
var _result: Label
var _progress_dots: Array[ColorRect] = []  ## indicador visual de quantas acertou
var _intro_label: Label


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_generate_sequence()


func _build() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.88)  ## bem opaco — esconde o gameplay atrás
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.position = Vector2(-PANEL_WIDTH * 0.5, -PANEL_HEIGHT * 0.5)
	panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.10, 1.0)
	sb.border_color = Color("#ffeb3b")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var title := Label.new()
	title.text = "RESTAURE O CARTUCHO"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#ffeb3b"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 12)
	title.size = Vector2(PANEL_WIDTH - 24, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	_instructions = Label.new()
	_instructions.text = ""
	_instructions.add_theme_font_size_override("font_size", 12)
	_instructions.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_instructions.position = Vector2(12, 40)
	_instructions.size = Vector2(PANEL_WIDTH - 24, 14)
	_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_instructions)

	# Setas em cruz no centro — UP em cima, LEFT/DOWN/RIGHT abaixo em fila
	var arrow_size := Vector2(70, 70)
	var center_x: float = PANEL_WIDTH * 0.5
	var arrow_y: float = 90
	_arrow_rects[Direction.UP] = _make_arrow(
		"▲", DIR_COLORS[Direction.UP],
		Vector2(center_x - arrow_size.x * 0.5, arrow_y)
	)
	_arrow_rects[Direction.LEFT] = _make_arrow(
		"◀", DIR_COLORS[Direction.LEFT],
		Vector2(center_x - arrow_size.x * 1.8, arrow_y + 80)
	)
	_arrow_rects[Direction.DOWN] = _make_arrow(
		"▼", DIR_COLORS[Direction.DOWN],
		Vector2(center_x - arrow_size.x * 0.5, arrow_y + 80)
	)
	_arrow_rects[Direction.RIGHT] = _make_arrow(
		"▶", DIR_COLORS[Direction.RIGHT],
		Vector2(center_x + arrow_size.x * 0.8, arrow_y + 80)
	)
	for r in _arrow_rects.values():
		panel.add_child(r)

	# Linha de "progress dots" no rodapé — visual de quantas acertou.
	var dot_y: float = PANEL_HEIGHT - 78
	var dot_size: float = 12
	var dot_gap: float = 8
	var dots_total_w: float = SEQUENCE_LENGTH * dot_size + (SEQUENCE_LENGTH - 1) * dot_gap
	var dots_start_x: float = (PANEL_WIDTH - dots_total_w) * 0.5
	for i in SEQUENCE_LENGTH:
		var dot := ColorRect.new()
		dot.color = Color(0.2, 0.22, 0.28, 1.0)
		dot.position = Vector2(dots_start_x + i * (dot_size + dot_gap), dot_y)
		dot.size = Vector2(dot_size, dot_size)
		panel.add_child(dot)
		_progress_dots.append(dot)

	# Intro grande — instrução com chamada pra pressionar tecla
	_intro_label = Label.new()
	_intro_label.text = (
		"Memorize a sequência das setas e reproduza com\n"
		+ "as teclas de movimento (WASD ou ← ↑ ↓ →).\n\n"
		+ "Acertar = HP cheio + 80 tokens.\n"
		+ "Errar ou pular = sem bônus, segue a run.\n\n"
		+ "[ENTER] começar     [ESC] pular"
	)
	_intro_label.add_theme_font_size_override("font_size", 11)
	_intro_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_intro_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_intro_label.add_theme_constant_override("outline_size", 2)
	_intro_label.position = Vector2(12, 62)
	_intro_label.size = Vector2(PANEL_WIDTH - 24, PANEL_HEIGHT - 100)
	_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(_intro_label)

	# Esconde setas e dots durante intro — só aparecem quando começar
	for r in _arrow_rects.values():
		(r as Control).visible = false
	for d in _progress_dots:
		d.visible = false

	_result = Label.new()
	_result.text = ""
	_result.add_theme_font_size_override("font_size", 14)
	_result.add_theme_color_override("font_color", Color.WHITE)
	_result.add_theme_color_override("font_outline_color", Color.BLACK)
	_result.add_theme_constant_override("outline_size", 2)
	_result.position = Vector2(12, PANEL_HEIGHT - 56)
	_result.size = Vector2(PANEL_WIDTH - 24, 18)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_result)

	var skip_hint := Label.new()
	skip_hint.text = "[ESC] pular puzzle"
	skip_hint.add_theme_font_size_override("font_size", 10)
	skip_hint.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	skip_hint.position = Vector2(12, PANEL_HEIGHT - 28)
	skip_hint.size = Vector2(PANEL_WIDTH - 24, 14)
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(skip_hint)


func _make_arrow(symbol: String, color: Color, pos: Vector2) -> Control:
	var wrap := Control.new()
	wrap.position = pos
	wrap.size = Vector2(70, 70)
	var bg := Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 1.0)
	sb.border_color = Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	bg.add_theme_stylebox_override("panel", sb)
	bg.name = "bg"
	wrap.add_child(bg)
	var lbl := Label.new()
	lbl.text = symbol
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.anchor_right = 1.0
	lbl.anchor_bottom = 1.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrap.add_child(lbl)
	return wrap


func _generate_sequence() -> void:
	_sequence.clear()
	for i in SEQUENCE_LENGTH:
		_sequence.append(randi() % 4)


## Inicializa o puzzle e mostra o INTRO. arena.gd chama isso, depois aguarda o
## signal `completed`. O sequence só roda depois que o player aperta ENTER.
func start() -> void:
	_state = State.INTRO
	_instructions.text = "Aperte ENTER quando estiver pronto"


## Esconde intro, mostra setas/dots e inicia a fase SHOWING.
func _begin_sequence() -> void:
	_intro_label.visible = false
	for r in _arrow_rects.values():
		(r as Control).visible = true
	for d in _progress_dots:
		d.visible = true
	_state = State.SHOWING
	_show_index = 0
	_state_timer = 0.6  ## pequeno delay antes da 1ª seta piscar
	_instructions.text = "OBSERVE..."


## Faz a seta de uma direção piscar acesa por um tempo.
func _flash(dir: int, duration: float) -> void:
	_flashed_dir = dir
	_flash_remaining = duration
	var wrap: Control = _arrow_rects.get(dir, null)
	if wrap == null:
		return
	var bg: Panel = wrap.get_node_or_null("bg") as Panel
	if bg == null:
		return
	var sb: StyleBoxFlat = bg.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		return
	# Highlight forte: bg fica saturado com a cor da seta
	sb.bg_color = Color(DIR_COLORS[dir].r * 0.55, DIR_COLORS[dir].g * 0.55, DIR_COLORS[dir].b * 0.55, 1.0)
	sb.border_color = Color.WHITE
	sb.set_border_width_all(4)


func _unflash(dir: int) -> void:
	var wrap: Control = _arrow_rects.get(dir, null)
	if wrap == null:
		return
	var bg: Panel = wrap.get_node_or_null("bg") as Panel
	if bg == null:
		return
	var sb: StyleBoxFlat = bg.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		return
	sb.bg_color = Color(0.06, 0.08, 0.12, 1.0)
	var c: Color = DIR_COLORS[dir]
	sb.border_color = Color(c.r * 0.4, c.g * 0.4, c.b * 0.4, 1.0)
	sb.set_border_width_all(2)


func _process(delta: float) -> void:
	# Unflash automático
	if _flash_remaining > 0.0:
		_flash_remaining -= delta
		if _flash_remaining <= 0.0 and _flashed_dir >= 0:
			_unflash(_flashed_dir)
			_flashed_dir = -1
	# SHOWING: acende uma seta, espera flash + gap, próxima
	if _state == State.SHOWING:
		_state_timer -= delta
		if _state_timer <= 0.0:
			if _show_index < _sequence.size():
				_flash(_sequence[_show_index], SHOW_FLASH_TIME)
				Audio.play(Audio.Sfx.UI_HOVER)
				_show_index += 1
				_state = State.GAP
				_state_timer = SHOW_FLASH_TIME + SHOW_GAP_TIME
			else:
				_state = State.INPUT
				_instructions.text = "AGORA REPRODUZA"
				_player_index = 0
	elif _state == State.GAP:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_state = State.SHOWING
			_state_timer = 0.0


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = (event as InputEventKey).keycode
	if key == KEY_ESCAPE:
		_finish(false)
		return
	if _state == State.INTRO:
		if key == KEY_ENTER or key == KEY_SPACE or key == KEY_KP_ENTER:
			_begin_sequence()
		return
	if _state != State.INPUT:
		return
	var pressed_dir: int = -1
	for d in DIR_ACTIONS.keys():
		if event.is_action_pressed(DIR_ACTIONS[d]):
			pressed_dir = d
			break
	if pressed_dir < 0:
		return
	_flash(pressed_dir, 0.25)
	if pressed_dir == _sequence[_player_index]:
		# Marca dot como acertado
		if _player_index < _progress_dots.size():
			_progress_dots[_player_index].color = Color("#9bbc0f")
		_player_index += 1
		Audio.play(Audio.Sfx.UI_SELECT)
		if _player_index >= _sequence.size():
			_finish(true)
	else:
		# Marca dot como erro
		if _player_index < _progress_dots.size():
			_progress_dots[_player_index].color = Color("#ff5252")
		Audio.play(Audio.Sfx.UI_ERROR)
		_finish(false)


func _finish(success: bool) -> void:
	if _state == State.DONE:
		return
	_state = State.DONE
	if success:
		_result.text = "▲ CARTUCHO RESTAURADO ▲"
		_result.add_theme_color_override("font_color", Color("#9bbc0f"))
		Audio.play(Audio.Sfx.LEVEL_UP)
	else:
		_result.text = "Sem bônus. Segue a run."
		_result.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
	# Aguarda 1.5s pra player ler o resultado, depois emite e fecha.
	var t := get_tree().create_timer(1.5, true, false, true)
	await t.timeout
	completed.emit(success)
