## Fundo da arena. Paleta + decorações lidas da Era selecionada.
## Inclui gradiente, grid sutil, estrelas, data streams horizontais animados,
## glitch dots flutuantes e vinheta de canto pra dar profundidade visual.
class_name ArenaBackground
extends Node2D

const GRID_STEP := 48
const SCANLINE_STEP := 3
const DATA_STREAM_COUNT := 6
const GLITCH_DOT_COUNT := 22

var _palette: Dictionary
var _is_16bit: bool = false
var _star_positions: Array[Vector2] = []
var _star_phases: Array[float] = []
# Data streams: linhas horizontais sutis que correm pra esquerda/direita
var _stream_y: Array[float] = []
var _stream_speed: Array[float] = []
var _stream_offset: Array[float] = []
var _stream_color: Array[Color] = []
# Glitch dots: pontos coloridos que flutuam suavemente
var _dot_positions: Array[Vector2] = []
var _dot_velocities: Array[Vector2] = []
var _dot_colors: Array[Color] = []
var _dot_phases: Array[float] = []


func _ready() -> void:
	z_index = -100
	var era: EraRegistry.EraDef = EraRegistry.get_def(GameState.selected_era_id)
	if era == null:
		era = EraRegistry.get_def("era_16bit")
	_palette = era.bg_palette
	_is_16bit = true
	_generate_stars()
	_generate_data_streams()
	_generate_glitch_dots()
	set_process(true)


func _generate_stars() -> void:
	var rect := ArenaBounds.get_rect()
	for i in 50:
		_star_positions.append(Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		))
		_star_phases.append(randf() * TAU)


func _generate_data_streams() -> void:
	var rect := ArenaBounds.get_rect()
	var palette_colors := [
		Color("#3949ab"),
		Color("#5e35b1"),
		Color("#00bcd4"),
		Color("#7e57c2"),
	]
	for i in DATA_STREAM_COUNT:
		_stream_y.append(randf_range(rect.position.y + 20, rect.end.y - 20))
		_stream_speed.append(randf_range(-90.0, 90.0))
		_stream_offset.append(randf() * 1000.0)
		_stream_color.append(palette_colors[i % palette_colors.size()])


func _generate_glitch_dots() -> void:
	var rect := ArenaBounds.get_rect()
	var dot_palette := [
		Color("#e040fb"),
		Color("#00e5ff"),
		Color("#ffeb3b"),
		Color("#69f0ae"),
	]
	for i in GLITCH_DOT_COUNT:
		_dot_positions.append(Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y),
		))
		var ang: float = randf() * TAU
		var spd: float = randf_range(6.0, 18.0)
		_dot_velocities.append(Vector2(cos(ang), sin(ang)) * spd)
		_dot_colors.append(dot_palette[i % dot_palette.size()])
		_dot_phases.append(randf() * TAU)


func _process(delta: float) -> void:
	var rect := ArenaBounds.get_rect()
	# Atualiza posição dos data streams
	for i in _stream_offset.size():
		_stream_offset[i] += _stream_speed[i] * delta
	# Movimento dos glitch dots com wrap-around
	for i in _dot_positions.size():
		_dot_positions[i] += _dot_velocities[i] * delta
		_dot_phases[i] += delta * 2.0
		if _dot_positions[i].x < rect.position.x - 4:
			_dot_positions[i].x = rect.end.x + 4
		elif _dot_positions[i].x > rect.end.x + 4:
			_dot_positions[i].x = rect.position.x - 4
		if _dot_positions[i].y < rect.position.y - 4:
			_dot_positions[i].y = rect.end.y + 4
		elif _dot_positions[i].y > rect.end.y + 4:
			_dot_positions[i].y = rect.position.y - 4
	queue_redraw()


func _draw() -> void:
	var rect := ArenaBounds.get_rect()
	var top: Color = _palette.get("bg_top", Color("#0f380f"))
	var bottom: Color = _palette.get("bg_bottom", top)
	var grid_color: Color = _palette.get("grid", Color("#306230"))
	var scan_color: Color = _palette.get("scan", Color(0, 0, 0, 0.18))

	# Gradiente vertical (várias linhas com cores interpoladas)
	if top.is_equal_approx(bottom):
		draw_rect(rect, top, true)
	else:
		var rows: int = int(rect.size.y)
		for yi in rows:
			var t: float = float(yi) / float(rows)
			var color := top.lerp(bottom, t)
			draw_line(
				Vector2(rect.position.x, rect.position.y + yi),
				Vector2(rect.end.x, rect.position.y + yi),
				color,
				1.0
			)

	# Estrelas piscando
	var time: float = float(Time.get_ticks_msec()) * 0.001
	for i in _star_positions.size():
		var pos := _star_positions[i]
		var phase := _star_phases[i]
		var bright: float = 0.4 + 0.5 * (sin(time * 1.6 + phase) * 0.5 + 0.5)
		draw_rect(Rect2(pos, Vector2(2, 2)), Color(1, 1, 1, bright * 0.5), true)

	# Data streams: linhas horizontais com pulso tracejado correndo
	for i in _stream_y.size():
		var sy: float = _stream_y[i]
		var offset: float = _stream_offset[i]
		var col := _stream_color[i]
		# Desenha "tracinhos" espaçados ao longo da linha — efeito de fluxo de dados
		var x: float = rect.position.x + fmod(offset, 24.0)
		while x < rect.end.x:
			var tracinho_w: float = 12.0
			var alpha: float = 0.20 + 0.18 * sin(time * 2.5 + x * 0.05)
			var c := Color(col.r, col.g, col.b, alpha)
			draw_line(
				Vector2(x, sy),
				Vector2(min(x + tracinho_w, rect.end.x), sy),
				c,
				1.5
			)
			x += 24.0

	# Glitch dots flutuantes pulsando
	for i in _dot_positions.size():
		var pos2 := _dot_positions[i]
		var col := _dot_colors[i]
		var pulse: float = 0.45 + 0.35 * sin(_dot_phases[i])
		var c := Color(col.r, col.g, col.b, pulse * 0.55)
		draw_rect(Rect2(pos2 - Vector2(1.5, 1.5), Vector2(3, 3)), c, true)

	# Grid sutil
	var gx: float = rect.position.x
	var grid_alpha := Color(grid_color.r, grid_color.g, grid_color.b, 0.5)
	while gx <= rect.end.x:
		draw_line(
			Vector2(gx, rect.position.y),
			Vector2(gx, rect.end.y),
			grid_alpha,
			1.0
		)
		gx += GRID_STEP
	var gy: float = rect.position.y
	while gy <= rect.end.y:
		draw_line(
			Vector2(rect.position.x, gy),
			Vector2(rect.end.x, gy),
			grid_alpha,
			1.0
		)
		gy += GRID_STEP

	# Scanlines bem suaves
	var line_y: int = int(rect.position.y)
	while line_y <= int(rect.end.y):
		draw_line(
			Vector2(rect.position.x, line_y),
			Vector2(rect.end.x, line_y),
			scan_color,
			1.0
		)
		line_y += SCANLINE_STEP

	# Vinheta de canto — escurece bordas pra dar profundidade
	var corners := 6
	for i in corners:
		var t: float = float(i) / float(corners)
		var alpha := (1.0 - t) * 0.10
		var col2 := Color(0.0, 0.0, 0.0, alpha)
		var margin: float = (1.0 - t) * 36.0
		# top
		draw_rect(Rect2(rect.position.x, rect.position.y + (1.0 - t) * 36.0 - margin, rect.size.x, margin), col2, true)
		# bottom
		draw_rect(Rect2(rect.position.x, rect.end.y - (1.0 - t) * 36.0, rect.size.x, margin), col2, true)
		# left
		draw_rect(Rect2(rect.position.x + (1.0 - t) * 36.0 - margin, rect.position.y, margin, rect.size.y), col2, true)
		# right
		draw_rect(Rect2(rect.end.x - (1.0 - t) * 36.0, rect.position.y, margin, rect.size.y), col2, true)
