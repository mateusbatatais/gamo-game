## Transições de cena: fade-out + change_scene + fade-in.
## Estilo "diamond wipe" — quadrados pretos crescem em padrão xadrez, cobrem
## a tela, troca a cena, encolhem revelando a nova. Feel SNES clássico.
##
## Uso:
##   await SceneTransition.go_to("res://scenes/arena.tscn")
extends CanvasLayer

const FADE_OUT_TIME := 0.4
const FADE_IN_TIME := 0.4
const GRID_COLS := 16
const GRID_ROWS := 9

var _overlay: Control
var _cells: Array[ColorRect] = []
var _busy: bool = false


func _ready() -> void:
	# Sempre por cima — layer alto + process_mode ALWAYS pra rodar durante pause.
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_grid()


func _build_grid() -> void:
	_overlay = Control.new()
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)

	# 16x9 grid de cells que crescem/encolhem. Cada cell ocupa 40x40 px na
	# viewport 640x360 (640/16 = 40, 360/9 = 40).
	var cell_w: float = 640.0 / float(GRID_COLS)
	var cell_h: float = 360.0 / float(GRID_ROWS)
	for y in GRID_ROWS:
		for x in GRID_COLS:
			var cell := ColorRect.new()
			cell.color = Color.BLACK
			cell.position = Vector2(x * cell_w + cell_w * 0.5, y * cell_h + cell_h * 0.5)
			cell.size = Vector2(cell_w, cell_h)
			cell.pivot_offset = Vector2(cell_w * 0.5, cell_h * 0.5)
			cell.scale = Vector2.ZERO
			_overlay.add_child(cell)
			_cells.append(cell)


## Faz transição completa: fade-out, troca cena, fade-in.
func go_to(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	_overlay.visible = true
	await _fade_out()
	get_tree().change_scene_to_file(scene_path)
	# Aguarda 1 frame pra cena nova rodar _ready
	await get_tree().process_frame
	await _fade_in()
	_overlay.visible = false
	_busy = false


## Fade-out: cells crescem em "wave" diagonal — começam pelos cantos.
func _fade_out() -> void:
	var per_cell_delay: float = 0.0
	for i in _cells.size():
		var cell := _cells[i]
		var x: int = i % GRID_COLS
		var y: int = i / GRID_COLS
		# Delay diagonal (canto top-left primeiro)
		var diag_t: float = float(x + y) / float(GRID_COLS + GRID_ROWS)
		per_cell_delay = diag_t * 0.18
		var tween := create_tween()
		tween.tween_interval(per_cell_delay)
		tween.tween_property(cell, "scale", Vector2.ONE, FADE_OUT_TIME - 0.18) \
			.set_ease(Tween.EASE_IN) \
			.set_trans(Tween.TRANS_QUAD)
	await get_tree().create_timer(FADE_OUT_TIME, true).timeout


## Fade-in: cells encolhem na ordem inversa.
func _fade_in() -> void:
	for i in _cells.size():
		var cell := _cells[i]
		var x: int = i % GRID_COLS
		var y: int = i / GRID_COLS
		# Reverso: canto bottom-right primeiro
		var diag_t: float = 1.0 - float(x + y) / float(GRID_COLS + GRID_ROWS)
		var delay: float = diag_t * 0.18
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(cell, "scale", Vector2.ZERO, FADE_IN_TIME - 0.18) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_QUAD)
	await get_tree().create_timer(FADE_IN_TIME, true).timeout
