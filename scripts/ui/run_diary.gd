## Diário de runs — painel com as últimas 10 sessões (vitória/derrota, tempo, kills, combo, era).
## Acessível pelo menu principal. Permite que o jogador acompanhe sua evolução.
class_name RunDiary
extends CanvasLayer

const PANEL_WIDTH := 520
const PANEL_HEIGHT := 320

var _root: Control


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
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
	sb.bg_color = Color(0.08, 0.10, 0.18, 1.0)
	sb.border_color = Color("#00e5ff")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var title := Label.new()
	title.text = "DIÁRIO DE RUNS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#00e5ff"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 8)
	title.size = Vector2(PANEL_WIDTH - 24, 22)
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Últimas %d sessões" % GameState.run_history.size()
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	subtitle.position = Vector2(12, 30)
	subtitle.size = Vector2(PANEL_WIDTH - 24, 12)
	panel.add_child(subtitle)

	# Header da tabela
	var header := Label.new()
	header.text = " #   RES.   TEMPO   KILLS  COMBO  FASE"
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	header.position = Vector2(12, 46)
	header.size = Vector2(PANEL_WIDTH - 24, 12)
	panel.add_child(header)

	# Linha separadora
	var sep := ColorRect.new()
	sep.color = Color(0.3, 0.35, 0.4, 1.0)
	sep.position = Vector2(12, 60)
	sep.size = Vector2(PANEL_WIDTH - 24, 1)
	panel.add_child(sep)

	if GameState.run_history.is_empty():
		var empty := Label.new()
		empty.text = "Nenhuma run registrada ainda.\nJogue para preencher o diário!"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		empty.position = Vector2(12, 90)
		empty.size = Vector2(PANEL_WIDTH - 24, 50)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(empty)
	else:
		var scroll := ScrollContainer.new()
		scroll.position = Vector2(12, 66)
		scroll.size = Vector2(PANEL_WIDTH - 24, PANEL_HEIGHT - 116)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		panel.add_child(scroll)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)
		scroll.add_child(vbox)

		var idx: int = 1
		for entry in GameState.run_history:
			vbox.add_child(_make_row(idx, entry))
			idx += 1

	var close_btn := _make_button("FECHAR")
	close_btn.position = Vector2(PANEL_WIDTH * 0.5 - 70, PANEL_HEIGHT - 36)
	close_btn.size = Vector2(140, 28)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)


func _make_row(idx: int, entry: Dictionary) -> Label:
	var victory: bool = entry.get("victory", false)
	var time_s: float = entry.get("time", 0.0)
	var kills: int = entry.get("kills", 0)
	var max_combo: int = entry.get("max_combo", 0)
	var stage_index: int = entry.get("stage_index", 0)
	var era_reached: String = entry.get("era_reached", "?")

	var result_txt: String = "WIN " if victory else "LOSS"
	var time_int := int(time_s)
	var time_txt := "%d:%02d" % [time_int / 60, time_int % 60]
	var era_short := _era_label(era_reached)

	var lbl := Label.new()
	lbl.text = "%02d   %s   %s   %4d   %4d   %d (%s)" % [
		idx, result_txt, time_txt, kills, max_combo, stage_index + 1, era_short
	]
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override(
		"font_color",
		Color("#9bbc0f") if victory else Color(0.85, 0.5, 0.45)
	)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 1)
	lbl.custom_minimum_size = Vector2(0, 14)
	return lbl


func _era_label(era_id: String) -> String:
	match era_id:
		"era_16bit":
			return "16-BIT"
		"era_32bit_cd":
			return "32-BIT CD"
		"era_64bit":
			return "64-BIT"
	return era_id


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.18, 1.0)
	sb.border_color = Color("#00e5ff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color(0.15, 0.2, 0.3, 1.0)
	sb_focus.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn


func open() -> void:
	for child in _root.get_children():
		child.queue_free()
	_root.queue_free()
	_root = null
	_build()
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		Audio.play(Audio.Sfx.UI_CANCEL)
		close()
		get_viewport().set_input_as_handled()
