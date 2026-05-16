## Painel de conquistas — mostra lista de todas com status desbloqueada/bloqueada.
## Aberto pelo botão CONQUISTAS na hub.
class_name AchievementsPanel
extends CanvasLayer

const PANEL_WIDTH := 520
const PANEL_HEIGHT := 320
const ROW_HEIGHT := 36

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
	dim.color = Color(0, 0, 0, 0.75)
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
	title.text = "CONQUISTAS"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#ffeb3b"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 8)
	title.size = Vector2(PANEL_WIDTH - 24, 24)
	panel.add_child(title)

	var counter := Label.new()
	var total: int = AchievementRegistry.all_ids().size()
	var unlocked: int = GameState.achievements_unlocked.size()
	counter.text = "%d / %d" % [unlocked, total]
	counter.add_theme_font_size_override("font_size", 14)
	counter.add_theme_color_override("font_color", Color("#9bbc0f"))
	counter.add_theme_color_override("font_outline_color", Color.BLACK)
	counter.add_theme_constant_override("outline_size", 2)
	counter.position = Vector2(PANEL_WIDTH - 100, 10)
	counter.size = Vector2(90, 18)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(counter)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12, 38)
	scroll.size = Vector2(PANEL_WIDTH - 24, PANEL_HEIGHT - 88)
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	scroll.add_child(vbox)

	for id in AchievementRegistry.all_ids():
		vbox.add_child(_make_row(id))

	var close_btn := _make_button("FECHAR")
	close_btn.position = Vector2(PANEL_WIDTH * 0.5 - 70, PANEL_HEIGHT - 36)
	close_btn.size = Vector2(140, 28)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)


func _make_row(id: String) -> Panel:
	var def: AchievementRegistry.AchievementDef = AchievementRegistry.get_def(id)
	var is_unlocked: bool = GameState.is_achievement_unlocked(id)
	var row := Panel.new()
	row.custom_minimum_size = Vector2(PANEL_WIDTH - 40, ROW_HEIGHT)
	var rb := StyleBoxFlat.new()
	rb.bg_color = Color(0.06, 0.08, 0.12, 1.0) if is_unlocked else Color(0.03, 0.04, 0.06, 1.0)
	rb.border_color = Color("#9bbc0f") if is_unlocked else Color(0.2, 0.2, 0.2)
	rb.set_border_width_all(1)
	rb.set_corner_radius_all(3)
	row.add_theme_stylebox_override("panel", rb)

	var status := Label.new()
	status.text = "✓" if is_unlocked else "🔒"
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("#9bbc0f") if is_unlocked else Color(0.4, 0.4, 0.4))
	status.position = Vector2(6, 10)
	status.size = Vector2(20, 16)
	row.add_child(status)

	var name_lbl := Label.new()
	name_lbl.text = def.display_name
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.45, 0.45, 0.5))
	name_lbl.position = Vector2(30, 3)
	name_lbl.size = Vector2(160, 16)
	row.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = def.description
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85) if is_unlocked else Color(0.35, 0.35, 0.4))
	desc_lbl.position = Vector2(30, 18)
	desc_lbl.size = Vector2(PANEL_WIDTH - 80, 14)
	desc_lbl.clip_text = true
	row.add_child(desc_lbl)

	return row


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.18, 1.0)
	sb.border_color = Color("#ffeb3b")
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
	# Rebuild pra refletir conquistas recém-desbloqueadas.
	for child in _root.get_children():
		child.queue_free()
	# _build() vai adicionar de novo dentro do _root.
	# Mas precisamos remover o próprio _root pra não duplicar, e reconstruir do zero.
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
