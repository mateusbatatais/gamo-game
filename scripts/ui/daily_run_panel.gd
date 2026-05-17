## Painel da Run Diária — mostra desafio do dia, status (jogada ou não),
## score do dia + histórico dos últimos 7 dias. Botão "JOGAR" inicia uma run
## com a seed do dia aplicada globalmente.
class_name DailyRunPanel
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
	dim.color = Color(0, 0, 0, 0.85)
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
	sb.border_color = Color("#ffeb3b")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var title := Label.new()
	title.text = "RUN DIÁRIA"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#ffeb3b"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 8)
	title.size = Vector2(PANEL_WIDTH - 24, 24)
	panel.add_child(title)

	# Mostra a data + seed à direita do título.
	var date_lbl := Label.new()
	var date_d: Dictionary = Time.get_date_dict_from_system(true)
	date_lbl.text = "%04d-%02d-%02d  |  SEED %d" % [
		date_d.get("year", 2026),
		date_d.get("month", 1),
		date_d.get("day", 1),
		DailyRun.today_seed,
	]
	date_lbl.add_theme_font_size_override("font_size", 11)
	date_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	date_lbl.position = Vector2(PANEL_WIDTH - 220, 12)
	date_lbl.size = Vector2(208, 14)
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(date_lbl)

	var lore := Label.new()
	lore.text = "Mesma seed pra todos. Mesma sequência de inimigos, ofertas e drops.\nCompare seu score com o resto da galera."
	lore.add_theme_font_size_override("font_size", 10)
	lore.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	lore.position = Vector2(12, 36)
	lore.size = Vector2(PANEL_WIDTH - 24, 28)
	panel.add_child(lore)

	# Status box — mostra o estado de hoje
	var status_panel := Panel.new()
	status_panel.position = Vector2(12, 70)
	status_panel.size = Vector2(PANEL_WIDTH - 24, 70)
	var status_sb := StyleBoxFlat.new()
	status_sb.bg_color = Color(0.04, 0.06, 0.10, 1.0)
	status_sb.border_color = Color(0.3, 0.35, 0.4)
	status_sb.set_border_width_all(1)
	status_sb.set_corner_radius_all(3)
	status_panel.add_theme_stylebox_override("panel", status_sb)
	panel.add_child(status_panel)

	if DailyRun.today_completed:
		var done_lbl := Label.new()
		done_lbl.text = "RUN DE HOJE CONCLUÍDA"
		done_lbl.add_theme_font_size_override("font_size", 14)
		done_lbl.add_theme_color_override("font_color", Color("#9bbc0f"))
		done_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		done_lbl.add_theme_constant_override("outline_size", 2)
		done_lbl.position = Vector2(12, 8)
		done_lbl.size = Vector2(status_panel.size.x - 24, 18)
		status_panel.add_child(done_lbl)

		var score_lbl := Label.new()
		score_lbl.text = "SCORE: %d" % DailyRun.today_score
		score_lbl.add_theme_font_size_override("font_size", 22)
		score_lbl.add_theme_color_override("font_color", Color("#ffeb3b"))
		score_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		score_lbl.add_theme_constant_override("outline_size", 3)
		score_lbl.position = Vector2(12, 28)
		score_lbl.size = Vector2(status_panel.size.x - 24, 30)
		status_panel.add_child(score_lbl)

		var hint := Label.new()
		hint.text = "Volte amanhã para o próximo desafio."
		hint.add_theme_font_size_override("font_size", 10)
		hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		hint.position = Vector2(status_panel.size.x - 280, 44)
		hint.size = Vector2(268, 14)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_panel.add_child(hint)
	else:
		var prompt := Label.new()
		prompt.text = "Desafio de hoje aguardando."
		prompt.add_theme_font_size_override("font_size", 12)
		prompt.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
		prompt.position = Vector2(12, 10)
		prompt.size = Vector2(280, 16)
		status_panel.add_child(prompt)

		var warn := Label.new()
		warn.text = "1 tentativa por dia. Escolha bem."
		warn.add_theme_font_size_override("font_size", 10)
		warn.add_theme_color_override("font_color", Color(0.95, 0.6, 0.5))
		warn.position = Vector2(12, 30)
		warn.size = Vector2(280, 14)
		status_panel.add_child(warn)

		var play_btn := _make_button("JOGAR AGORA", true)
		play_btn.position = Vector2(status_panel.size.x - 170, 18)
		play_btn.size = Vector2(150, 36)
		play_btn.pressed.connect(_on_play_daily)
		status_panel.add_child(play_btn)

	# Histórico (últimos 7 dias)
	var hist_label := Label.new()
	hist_label.text = "ÚLTIMOS 7 DIAS"
	hist_label.add_theme_font_size_override("font_size", 11)
	hist_label.add_theme_color_override("font_color", Color("#00e5ff"))
	hist_label.position = Vector2(12, 148)
	hist_label.size = Vector2(PANEL_WIDTH - 24, 14)
	panel.add_child(hist_label)

	# Header da tabela do histórico
	var header := Label.new()
	header.text = " DATA          RES.    SCORE"
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	header.position = Vector2(12, 164)
	header.size = Vector2(PANEL_WIDTH - 24, 12)
	panel.add_child(header)

	var sep := ColorRect.new()
	sep.color = Color(0.3, 0.35, 0.4, 1.0)
	sep.position = Vector2(12, 178)
	sep.size = Vector2(PANEL_WIDTH - 24, 1)
	panel.add_child(sep)

	if DailyRun.history.is_empty():
		var empty := Label.new()
		empty.text = "Sem runs registradas. Jogue a primeira hoje!"
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		empty.position = Vector2(12, 200)
		empty.size = Vector2(PANEL_WIDTH - 24, 16)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(empty)
	else:
		var y_off: float = 184
		for entry in DailyRun.history:
			var row := Label.new()
			var victory: bool = entry.get("victory", false)
			var date_str: String = entry.get("date", "?")
			var score: int = int(entry.get("score", 0))
			var res_txt: String = "VITORIA" if victory else "DERROTA"
			row.text = " %s    %s   %d" % [date_str, res_txt, score]
			row.add_theme_font_size_override("font_size", 11)
			row.add_theme_color_override(
				"font_color",
				Color("#9bbc0f") if victory else Color(0.85, 0.5, 0.45)
			)
			row.add_theme_color_override("font_outline_color", Color.BLACK)
			row.add_theme_constant_override("outline_size", 1)
			row.position = Vector2(12, y_off)
			row.size = Vector2(PANEL_WIDTH - 24, 14)
			panel.add_child(row)
			y_off += 14

	var close_btn := _make_button("FECHAR", false)
	close_btn.position = Vector2(PANEL_WIDTH * 0.5 - 70, PANEL_HEIGHT - 36)
	close_btn.size = Vector2(140, 28)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)


func _make_button(text: String, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.18, 0.10, 1.0) if primary else Color(0.08, 0.12, 0.18, 1.0)
	sb.border_color = Color("#ffeb3b") if primary else Color("#00e5ff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color(0.30, 0.30, 0.10, 1.0) if primary else Color(0.15, 0.2, 0.3, 1.0)
	sb_focus.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn


func _on_play_daily() -> void:
	if not DailyRun.start_daily_run():
		Audio.play(Audio.Sfx.UI_ERROR)
		return
	Audio.play(Audio.Sfx.UI_CONFIRM)
	close()
	# A seed já foi aplicada por DailyRun.start_daily_run().
	# A arena chama GameState.start_run() em _ready, então não chamamos aqui
	# pra não consumir RNG duas vezes.
	SceneRouter.go_to_arena()


func open() -> void:
	DailyRun.refresh_for_new_day()
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
