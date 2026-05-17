## Overlay "STAGE CLEARED" entre fases da run.
## Mostra título + nome da próxima era + stats curtos + botão "AVANÇAR".
## Roda com PROCESS_MODE_ALWAYS porque a árvore fica pausada durante a tela.
class_name StageCleared
extends CanvasLayer

signal advance_requested

const SHOW_DURATION_MIN := 1.6  # mínimo de tempo visível antes de poder avançar

var _root: Control
var _title_label: Label
var _next_era_label: Label
var _continue_btn: Button
var _age: float = 0.0
var _can_advance: bool = false


func _ready() -> void:
	layer = 9
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
	dim.color = Color(0, 0, 0, 0.78)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	_title_label = Label.new()
	_title_label.text = "FASE COMPLETA"
	_title_label.add_theme_font_size_override("font_size", 44)
	_title_label.add_theme_color_override("font_color", Color("#9bbc0f"))
	_title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_title_label.add_theme_constant_override("outline_size", 5)
	_title_label.anchor_left = 0.5
	_title_label.anchor_right = 0.5
	_title_label.anchor_top = 0.5
	_title_label.position = Vector2(-280, -90)
	_title_label.size = Vector2(560, 56)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.pivot_offset = Vector2(280, 28)
	_root.add_child(_title_label)

	_next_era_label = Label.new()
	_next_era_label.add_theme_font_size_override("font_size", 18)
	_next_era_label.add_theme_color_override("font_color", Color("#00e5ff"))
	_next_era_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_next_era_label.add_theme_constant_override("outline_size", 3)
	_next_era_label.anchor_left = 0.5
	_next_era_label.anchor_right = 0.5
	_next_era_label.anchor_top = 0.5
	_next_era_label.position = Vector2(-200, -24)
	_next_era_label.size = Vector2(400, 24)
	_next_era_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_next_era_label)

	var stats_panel := Panel.new()
	stats_panel.anchor_left = 0.5
	stats_panel.anchor_right = 0.5
	stats_panel.anchor_top = 0.5
	stats_panel.position = Vector2(-160, 16)
	stats_panel.size = Vector2(320, 60)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.9)
	sb.border_color = Color("#9bbc0f")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	stats_panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(stats_panel)

	_continue_btn = Button.new()
	_continue_btn.text = "AVANCAR"
	_continue_btn.custom_minimum_size = Vector2(180, 32)
	_continue_btn.anchor_left = 0.5
	_continue_btn.anchor_right = 0.5
	_continue_btn.anchor_top = 0.5
	_continue_btn.position = Vector2(-90, 92)
	_continue_btn.add_theme_font_size_override("font_size", 16)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color("#1b3b1b")
	bsb.border_color = Color("#9bbc0f")
	bsb.set_border_width_all(3)
	bsb.set_corner_radius_all(0)
	_continue_btn.add_theme_stylebox_override("normal", bsb)
	_continue_btn.add_theme_color_override("font_color", Color.WHITE)
	_continue_btn.pressed.connect(_on_advance)
	_root.add_child(_continue_btn)


## Mostra a tela com stats da fase recém-completada.
## next_era_name é o nome da próxima fase (mostrado pra dar antecipação).
func show_for_stage(stage_label: String, next_era_name: String, stats: Dictionary) -> void:
	_title_label.text = "%s — COMPLETA" % stage_label
	_next_era_label.text = "→ %s" % next_era_name.to_upper()
	_age = 0.0
	_can_advance = false
	_continue_btn.disabled = true
	_populate_stats(stats)
	visible = true
	get_tree().paused = true


func _populate_stats(stats: Dictionary) -> void:
	# Remove labels antigos
	for child in _root.get_children():
		if child is Panel:
			for c in child.get_children():
				c.queue_free()
			# Adiciona novos stats
			var time_s: int = int(stats.get("time", 0.0))
			var time_str: String = "%d:%02d" % [time_s / 60, time_s % 60]
			var lines := [
				["TEMPO", time_str],
				["KILLS", str(stats.get("kills", 0))],
				["COMBO MAX", "x%d" % stats.get("max_combo", 0)],
				["TOKENS", "%d T" % stats.get("tokens", 0)],
			]
			for i in lines.size():
				var lbl_name := Label.new()
				lbl_name.text = lines[i][0]
				lbl_name.add_theme_font_size_override("font_size", 11)
				lbl_name.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
				lbl_name.position = Vector2(12 + (i % 2) * 156, 6 + (i / 2) * 24)
				lbl_name.size = Vector2(80, 14)
				child.add_child(lbl_name)
				var lbl_val := Label.new()
				lbl_val.text = lines[i][1]
				lbl_val.add_theme_font_size_override("font_size", 13)
				lbl_val.add_theme_color_override("font_color", Color("#ffeb3b"))
				lbl_val.position = Vector2(82 + (i % 2) * 156, 4 + (i / 2) * 24)
				lbl_val.size = Vector2(68, 16)
				child.add_child(lbl_val)
			break


func _process(delta: float) -> void:
	if not visible:
		return
	_age += delta
	# Pulso de scale no título nos primeiros 0.6s
	if _age < 0.6:
		var t: float = _age / 0.6
		var s: float = 0.3 + (1.0 - pow(1.0 - t, 3.0)) * 0.85  # ease-out cubic
		_title_label.scale = Vector2(s, s)
	else:
		_title_label.scale = Vector2.ONE
	# Libera o botão após o mínimo de tempo
	if not _can_advance and _age >= SHOW_DURATION_MIN:
		_can_advance = true
		_continue_btn.disabled = false
		_continue_btn.grab_focus()


func _on_advance() -> void:
	if not _can_advance:
		return
	get_tree().paused = false
	visible = false
	advance_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _can_advance:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_confirm"):
		_on_advance()
		get_viewport().set_input_as_handled()
