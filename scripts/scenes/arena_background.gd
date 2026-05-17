## Fundo da arena em 3 camadas (back → front):
##   1. Gradient dark-green + estante de cartuchos com parallax lento (3 fileiras)
##   2. Placa de circuito (PCB) — trilhas, pads dourados pulsantes, chips com pinos
##   3. Glitch dots flutuantes + data streams + scanlines + vinheta de canto
##
## Conceito: o GAMO defende a Coleção Eterna dentro de um cartucho corrompido.
## A estante = a Coleção; o PCB = o hardware do cartucho; os glitches = a corrupção.
class_name ArenaBackground
extends Node2D

# --- Layer 2: PCB ---
const PCB_TRACE_COUNT := 10
const PCB_PAD_COUNT := 14
const PCB_CHIP_COUNT := 3

# --- Layer 1: Cartridge shelf ---
const SHELF_Y_POSITIONS: Array[float] = [40.0, 168.0, 296.0]
const SHELF_PARALLAX_SPEEDS: Array[float] = [3.0, 4.5, 6.0]
const CART_W := 28
const CART_H := 38
const CART_GAP := 6

# --- Layer 3: glitch atmosphere ---
const SCANLINE_STEP := 3
const DATA_STREAM_COUNT := 3
const GLITCH_DOT_COUNT := 8

# Paletas — defaults Era 16-bit. Trocadas em runtime por set_era()
var color_bg_top: Color = Color("#061508")
var color_bg_bottom: Color = Color("#020a04")
var color_trace: Color = Color("#1f5a1f")
var color_pad: Color = Color("#d4a017")
var color_chip: Color = Color("#0a0a0a")
var color_chip_pin: Color = Color("#9e9e9e")
const COLOR_SCAN := Color(0, 0, 0, 0.18)

# Modo "disco CD" — adiciona anéis concêntricos rotacionando no fundo da Era 2.
var _show_cd_disc: bool = false
var _cd_rotation: float = 0.0

const CARTRIDGE_COLORS: Array[Color] = [
	Color("#c62828"), Color("#1565c0"), Color("#f9a825"),
	Color("#2e7d32"), Color("#6a1b9a"), Color("#ef6c00"),
	Color("#00838f"), Color("#ad1457"), Color("#5d4037"),
]

# Cartuchos: dicionário {row, x, y, color}
var _carts: Array = []
var _shelf_offsets: Array[float] = [0.0, 0.0, 0.0]

# PCB: traces (PackedVector2Array), pads (Vector2), chips (Dict)
var _traces: Array = []
var _pads: Array[Vector2] = []
var _pad_phases: Array[float] = []
var _chips: Array = []

# Glitch atmosphere
var _dot_positions: Array[Vector2] = []
var _dot_velocities: Array[Vector2] = []
var _dot_colors: Array[Color] = []
var _dot_phases: Array[float] = []
var _stream_y: Array[float] = []
var _stream_speed: Array[float] = []
var _stream_offset: Array[float] = []
var _stream_color: Array[Color] = []

# Parallax distante — "motes" que dão profundidade sem competir com gameplay.
# Comportamento varia por era (deriva preguiçosa na 16-bit, gira em 32-bit, vibra na 64-bit).
const PARALLAX_MOTE_COUNT := 36
var _mote_positions: Array[Vector2] = []
var _mote_phases: Array[float] = []
var _mote_sizes: Array[float] = []
var _mote_color: Color = Color(0.4, 0.7, 0.4, 0.18)
var _mote_drift: Vector2 = Vector2(8.0, 4.0)  ## velocidade base (sobrescrito por era)


func _ready() -> void:
	z_index = -100
	_apply_era_palette(GameState.selected_era_id)
	_generate_shelf()
	_generate_pcb()
	_generate_glitch_atmosphere()
	_generate_parallax_motes()
	set_process(true)


## Troca a paleta do background pra refletir a era atual.
## Pode ser chamado quando troca de fase pra dar feel "muda tudo".
func set_era(era_id: String) -> void:
	_apply_era_palette(era_id)
	queue_redraw()


func _apply_era_palette(era_id: String) -> void:
	match era_id:
		"era_32bit_cd":
			# Era CD — tons azul-noite + roxo MAIS saturados, ciano vibrante.
			color_bg_top = Color("#1a1a5e")
			color_bg_bottom = Color("#2a0a4a")
			color_trace = Color("#7e57c2")  # roxo-disco brilhante
			color_pad = Color("#00e5ff")    # leitura óptica ciano
			color_chip = Color("#0a0a24")
			color_chip_pin = Color("#b388ff")
			_show_cd_disc = true
			_mote_color = Color(0.5, 0.85, 1.0, 0.22)  # ciano gélido
			_mote_drift = Vector2(20.0, -6.0)          # deriva rápida horizontal (efeito leitor)
		"era_64bit":
			# Era 64-bit — cinza-fog poligonal + roxo escuro. Padrão de
			# wireframe sutil no fundo (sem disco CD).
			color_bg_top = Color("#3a3a4f")
			color_bg_bottom = Color("#1a0a3a")
			color_trace = Color("#90a4ae")  # cinza-fog claro (linhas wireframe)
			color_pad = Color("#ff80ab")    # nodes rosa-pastel
			color_chip = Color("#1a1a2e")
			color_chip_pin = Color("#7e57c2")
			_show_cd_disc = false
			_mote_color = Color(0.9, 0.6, 1.0, 0.20)  # roxo brilhante (polígonos perdidos)
			_mote_drift = Vector2(-4.0, 14.0)         # cai como neblina/fog
		_:
			# Era 16-bit (default verde-PCB).
			color_bg_top = Color("#061508")
			color_bg_bottom = Color("#020a04")
			color_trace = Color("#1f5a1f")
			color_pad = Color("#d4a017")
			color_chip = Color("#0a0a0a")
			color_chip_pin = Color("#9e9e9e")
			_show_cd_disc = false
			_mote_color = Color(0.6, 0.95, 0.5, 0.16)  # verde-PCB suave
			_mote_drift = Vector2(8.0, 4.0)            # deriva preguiçosa


# === Geração estática ===

func _generate_shelf() -> void:
	var rect := ArenaBounds.get_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7271
	# Cartuchos suficientes pra preencher a linha + sobra pro wrap-around.
	var row_count: int = SHELF_Y_POSITIONS.size()
	var col_count: int = int(rect.size.x / float(CART_W + CART_GAP)) + 3
	for row in row_count:
		for col in col_count:
			var x: float = float(col) * float(CART_W + CART_GAP) + rect.position.x
			var color: Color = CARTRIDGE_COLORS[rng.randi() % CARTRIDGE_COLORS.size()]
			_carts.append({
				"row": row,
				"base_x": x,
				"y": SHELF_Y_POSITIONS[row],
				"color": color,
			})


func _generate_pcb() -> void:
	var rect := ArenaBounds.get_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	# Trilhas geométricas (linhas em ângulo reto) percorrendo o tabuleiro.
	for i in PCB_TRACE_COUNT:
		var pts: PackedVector2Array = PackedVector2Array()
		var x: float = rng.randf_range(rect.position.x + 20, rect.end.x - 20)
		var y: float = rng.randf_range(rect.position.y + 20, rect.end.y - 20)
		pts.append(Vector2(x, y))
		var segments: int = rng.randi_range(4, 7)
		var go_horizontal: bool = rng.randf() < 0.5
		for s in segments:
			if go_horizontal:
				x += rng.randf_range(40.0, 110.0) * (1.0 if rng.randf() < 0.5 else -1.0)
			else:
				y += rng.randf_range(40.0, 110.0) * (1.0 if rng.randf() < 0.5 else -1.0)
			x = clampf(x, rect.position.x + 12, rect.end.x - 12)
			y = clampf(y, rect.position.y + 12, rect.end.y - 12)
			pts.append(Vector2(x, y))
			go_horizontal = not go_horizontal
		_traces.append(pts)
	# Pads dourados pulsantes (alguns nos endpoints das trilhas, outros aleatórios).
	for trace in _traces:
		var arr: PackedVector2Array = trace
		if arr.size() > 0:
			_pads.append(arr[0])
			_pads.append(arr[arr.size() - 1])
	while _pads.size() < PCB_PAD_COUNT:
		_pads.append(Vector2(
			rng.randf_range(rect.position.x + 16, rect.end.x - 16),
			rng.randf_range(rect.position.y + 16, rect.end.y - 16)
		))
	for i in _pads.size():
		_pad_phases.append(rng.randf() * TAU)
	# Chips: retângulos escuros com pinos verticais.
	for i in PCB_CHIP_COUNT:
		var cx: float = rng.randf_range(rect.position.x + 60, rect.end.x - 60)
		var cy: float = rng.randf_range(rect.position.y + 60, rect.end.y - 60)
		var cw: float = rng.randf_range(48.0, 76.0)
		var ch: float = rng.randf_range(22.0, 36.0)
		_chips.append({
			"rect": Rect2(cx - cw * 0.5, cy - ch * 0.5, cw, ch),
			"pins_h": int(cw / 7.0),
			"led_phase": rng.randf() * TAU,
		})


## Gera o campo de "motes" — pontos minúsculos que dão sensação de
## ambient/profundidade. Distribuídos aleatoriamente, com tamanhos variando.
func _generate_parallax_motes() -> void:
	var rect := ArenaBounds.get_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	for i in PARALLAX_MOTE_COUNT:
		_mote_positions.append(Vector2(
			rng.randf_range(rect.position.x, rect.end.x),
			rng.randf_range(rect.position.y, rect.end.y)
		))
		_mote_phases.append(rng.randf() * TAU)
		_mote_sizes.append(rng.randf_range(1.0, 2.5))


func _generate_glitch_atmosphere() -> void:
	var rect := ArenaBounds.get_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = 9999
	# Glitch dots
	var dot_palette: Array[Color] = [
		Color("#e040fb"), Color("#00e5ff"), Color("#ffeb3b"), Color("#69f0ae")
	]
	for i in GLITCH_DOT_COUNT:
		_dot_positions.append(Vector2(
			rng.randf_range(rect.position.x, rect.end.x),
			rng.randf_range(rect.position.y, rect.end.y)
		))
		var ang: float = rng.randf() * TAU
		var spd: float = rng.randf_range(6.0, 18.0)
		_dot_velocities.append(Vector2(cos(ang), sin(ang)) * spd)
		_dot_colors.append(dot_palette[i % dot_palette.size()])
		_dot_phases.append(rng.randf() * TAU)
	# Data streams
	var stream_palette: Array[Color] = [
		Color("#3949ab"), Color("#5e35b1"), Color("#00bcd4"), Color("#7e57c2"),
	]
	for i in DATA_STREAM_COUNT:
		_stream_y.append(rng.randf_range(rect.position.y + 20, rect.end.y - 20))
		_stream_speed.append(rng.randf_range(-70.0, 70.0))
		_stream_offset.append(rng.randf() * 1000.0)
		_stream_color.append(stream_palette[i % stream_palette.size()])


# === Update por frame ===

func _process(delta: float) -> void:
	var rect := ArenaBounds.get_rect()
	# Parallax da estante
	for i in _shelf_offsets.size():
		_shelf_offsets[i] = fmod(
			_shelf_offsets[i] + SHELF_PARALLAX_SPEEDS[i] * delta,
			float(CART_W + CART_GAP)
		)
	# Rotação do disco CD (Era 2)
	if _show_cd_disc:
		_cd_rotation += delta * 0.3
	# Glitch dots com wrap
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
	# Data streams
	for i in _stream_offset.size():
		_stream_offset[i] += _stream_speed[i] * delta
	# Parallax motes — deriva contínua, wrap nas bordas. Fase pulsa pra "twinkle".
	for i in _mote_positions.size():
		_mote_positions[i] += _mote_drift * delta
		_mote_phases[i] += delta * 1.6
		if _mote_positions[i].x < rect.position.x - 4:
			_mote_positions[i].x = rect.end.x + 4
		elif _mote_positions[i].x > rect.end.x + 4:
			_mote_positions[i].x = rect.position.x - 4
		if _mote_positions[i].y < rect.position.y - 4:
			_mote_positions[i].y = rect.end.y + 4
		elif _mote_positions[i].y > rect.end.y + 4:
			_mote_positions[i].y = rect.position.y - 4
	queue_redraw()


# === Renderização ===

func _draw() -> void:
	var rect := ArenaBounds.get_rect()
	_draw_gradient(rect)
	_draw_parallax_motes(rect)  ## entre gradient e CD/shelf — camada mais distante
	if _show_cd_disc:
		_draw_cd_disc(rect)
	_draw_shelf(rect)
	_draw_pcb(rect)
	_draw_glitch_layer(rect)
	_draw_scanlines(rect)
	_draw_vignette(rect)


## Desenha o campo de motes. Cor e tamanho com twinkle (modulado por fase).
func _draw_parallax_motes(_rect: Rect2) -> void:
	for i in _mote_positions.size():
		var pos := _mote_positions[i]
		var size := _mote_sizes[i]
		var twinkle: float = 0.6 + 0.4 * sin(_mote_phases[i])
		var col := Color(_mote_color.r, _mote_color.g, _mote_color.b, _mote_color.a * twinkle)
		# Cross pequeno (cruz de 1px) pra ficar com cara de "estrela pixel" em vez de bolinha.
		draw_rect(Rect2(pos - Vector2(size * 0.5, 0.5), Vector2(size, 1.0)), col, true)
		draw_rect(Rect2(pos - Vector2(0.5, size * 0.5), Vector2(1.0, size)), col, true)


## Desenha um disco CD gigante girando no fundo (só Era 32-bit).
## Anéis concêntricos + raios irradiando + reflexo iridescente.
func _draw_cd_disc(rect: Rect2) -> void:
	var center: Vector2 = rect.get_center()
	var max_r: float = 220.0
	# Anéis concêntricos com cores iridescentes (gradiente magenta→ciano).
	var rings := 14
	for i in rings:
		var r: float = max_r * (1.0 - float(i) / float(rings))
		# Iridescência: alterna entre tons roxos/cianos/magenta
		var hue_t: float = fmod(_cd_rotation * 0.2 + float(i) * 0.15, 1.0)
		var ring_col: Color = Color.from_hsv(0.55 + 0.25 * sin(hue_t * TAU), 0.55, 0.6)
		ring_col.a = 0.10
		draw_arc(center, r, 0.0, TAU, 64, ring_col, 1.5)
	# Raios irradiando do centro (24 raios rotacionando)
	var rays := 24
	for i in rays:
		var angle: float = _cd_rotation + TAU * float(i) / float(rays)
		var p1: Vector2 = center + Vector2(cos(angle), sin(angle)) * 40.0
		var p2: Vector2 = center + Vector2(cos(angle), sin(angle)) * max_r
		var ray_col := Color(0.7, 0.9, 1.0, 0.04)
		draw_line(p1, p2, ray_col, 1.0)
	# Hub central (buraco do CD)
	draw_circle(center, 26.0, Color(0.05, 0.0, 0.15, 0.5))
	draw_circle(center, 14.0, Color(0, 0, 0, 0.6))


func _draw_gradient(rect: Rect2) -> void:
	var rows: int = int(rect.size.y)
	for yi in rows:
		var t: float = float(yi) / float(rows)
		var color := color_bg_top.lerp(color_bg_bottom, t)
		draw_line(
			Vector2(rect.position.x, rect.position.y + yi),
			Vector2(rect.end.x, rect.position.y + yi),
			color, 1.0
		)


func _draw_shelf(rect: Rect2) -> void:
	# Cartuchos enfileirados, parallax horizontal, ESMAECIDOS COMO PAREDE.
	# Alphas baixíssimas pra ler como "fundo decorativo" e não confundir com itens.
	for cart in _carts:
		var row: int = cart["row"]
		var x: float = cart["base_x"] - _shelf_offsets[row]
		if x + CART_W < rect.position.x or x > rect.end.x:
			continue
		var y: float = cart["y"]
		var base: Color = cart["color"]
		# Tom muito escuro, mal dá pra ver a cor — é só uma "sugestão" de cartucho.
		var body := Color(base.r * 0.22, base.g * 0.22, base.b * 0.22, 0.30)
		draw_rect(Rect2(x, y, CART_W, CART_H), body, true)
		# Etiqueta sutil
		draw_rect(Rect2(x + 4, y + 5, CART_W - 8, 6), Color(0.5, 0.5, 0.55, 0.12), true)
	# Linha da prateleira embaixo de cada fileira (bem fraca)
	for row in SHELF_Y_POSITIONS.size():
		var sy: float = SHELF_Y_POSITIONS[row] + CART_H + 1.0
		if sy < rect.end.y:
			draw_line(
				Vector2(rect.position.x, sy),
				Vector2(rect.end.x, sy),
				Color(0.25, 0.20, 0.10, 0.15), 1.0
			)


func _draw_pcb(rect: Rect2) -> void:
	# Tudo ESTÁTICO e bem opaco — leitura como "textura de chão", não como objetos.
	var trace_col := Color(color_trace.r, color_trace.g, color_trace.b, 0.22)
	for trace in _traces:
		var pts: PackedVector2Array = trace
		for i in pts.size() - 1:
			draw_line(pts[i], pts[i + 1], trace_col, 1.0)
	var pad_col := Color(color_pad.r, color_pad.g, color_pad.b, 0.18)
	for p in _pads:
		draw_circle(p, 2.0, pad_col)
	var chip_col := Color(color_chip.r, color_chip.g, color_chip.b, 0.35)
	var pin_col := Color(color_chip_pin.r, color_chip_pin.g, color_chip_pin.b, 0.18)
	for chip in _chips:
		var r: Rect2 = chip["rect"]
		draw_rect(r, chip_col, true)
		var pins_h: int = chip["pins_h"]
		var pin_step: float = r.size.x / float(pins_h + 1)
		for p in pins_h:
			var px: float = r.position.x + pin_step * float(p + 1)
			draw_line(Vector2(px, r.position.y), Vector2(px, r.position.y - 3),
				pin_col, 1.0)
			draw_line(Vector2(px, r.end.y), Vector2(px, r.end.y + 3),
				pin_col, 1.0)


func _draw_glitch_layer(rect: Rect2) -> void:
	# Atmosfera reduzida — alphas mínimas pra não competir com gameplay.
	var time: float = float(Time.get_ticks_msec()) * 0.001
	# Data streams (tracinhos finos correndo, bem dim)
	for i in _stream_y.size():
		var sy: float = _stream_y[i]
		var offset: float = _stream_offset[i]
		var col: Color = _stream_color[i]
		var x: float = rect.position.x + fmod(offset, 28.0)
		while x < rect.end.x:
			var c := Color(col.r, col.g, col.b, 0.08)
			draw_line(
				Vector2(x, sy),
				Vector2(min(x + 10.0, rect.end.x), sy),
				c, 1.0
			)
			x += 28.0
	# Glitch dots (poucos, pequenos, dim)
	for i in _dot_positions.size():
		var pos := _dot_positions[i]
		var col: Color = _dot_colors[i]
		var c := Color(col.r, col.g, col.b, 0.20)
		draw_rect(Rect2(pos - Vector2(1, 1), Vector2(2, 2)), c, true)


func _draw_scanlines(rect: Rect2) -> void:
	var line_y: int = int(rect.position.y)
	while line_y <= int(rect.end.y):
		draw_line(
			Vector2(rect.position.x, line_y),
			Vector2(rect.end.x, line_y),
			COLOR_SCAN, 1.0
		)
		line_y += SCANLINE_STEP


func _draw_vignette(rect: Rect2) -> void:
	# Bandas escuras nas bordas pra dar profundidade.
	var corners := 6
	for i in corners:
		var t: float = float(i) / float(corners)
		var alpha: float = (1.0 - t) * 0.10
		var col := Color(0.0, 0.0, 0.0, alpha)
		var margin: float = (1.0 - t) * 36.0
		var ring: float = (1.0 - t) * 36.0 - margin
		draw_rect(Rect2(rect.position.x, rect.position.y + ring, rect.size.x, margin), col, true)
		draw_rect(Rect2(rect.position.x, rect.end.y - ring - margin, rect.size.x, margin), col, true)
		draw_rect(Rect2(rect.position.x + ring, rect.position.y, margin, rect.size.y), col, true)
		draw_rect(Rect2(rect.end.x - ring - margin, rect.position.y, margin, rect.size.y), col, true)
