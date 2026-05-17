## Painel "Arquivo" — lista todos os inimigos/bosses do codex com status
## (encontrado/desconhecido). Aberto pelo botão ARQUIVO na hub.
class_name CodexPanel
extends CanvasLayer

const PANEL_WIDTH := 560
const PANEL_HEIGHT := 320
const ROW_HEIGHT := 44

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
	dim.color = Color(0, 0, 0, 0.78)
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
	sb.border_color = Color("#e040fb")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var title := Label.new()
	title.text = "ARQUIVO DA COLEÇÃO"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#e040fb"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 8)
	title.size = Vector2(PANEL_WIDTH - 24, 24)
	panel.add_child(title)

	var ids := CodexRegistry.all_ids()
	var counter := Label.new()
	var encountered: int = 0
	for id in ids:
		if id in GameState.encountered_enemies:
			encountered += 1
	counter.text = "%d / %d" % [encountered, ids.size()]
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

	for id in ids:
		vbox.add_child(_make_row(id))

	var close_btn := _make_button("FECHAR")
	close_btn.position = Vector2(PANEL_WIDTH * 0.5 - 70, PANEL_HEIGHT - 36)
	close_btn.size = Vector2(140, 28)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)


func _make_row(id: String) -> Panel:
	var entry: CodexRegistry.CodexEntry = CodexRegistry.get_entry(id)
	var seen: bool = id in GameState.encountered_enemies
	var row := Panel.new()
	row.custom_minimum_size = Vector2(PANEL_WIDTH - 40, ROW_HEIGHT)

	var category_color: Color
	match entry.category:
		"BOSS":
			category_color = Color("#ff5252")
		"MINIBOSS":
			category_color = Color("#e040fb")
		_:
			category_color = Color("#9bbc0f")

	var rb := StyleBoxFlat.new()
	rb.bg_color = Color(0.06, 0.08, 0.12, 1.0) if seen else Color(0.03, 0.04, 0.06, 1.0)
	rb.border_color = category_color if seen else Color(0.2, 0.2, 0.22)
	rb.set_border_width_all(1)
	rb.set_corner_radius_all(3)
	row.add_theme_stylebox_override("panel", rb)

	# Preview sprite (à esquerda) ou silhueta preta
	var preview := TextureRect.new()
	var tex := CodexRegistry.make_preview(entry)
	if tex != null:
		preview.texture = tex
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.position = Vector2(4, 4)
	preview.size = Vector2(ROW_HEIGHT - 8, ROW_HEIGHT - 8)
	if not seen:
		preview.modulate = Color(0, 0, 0, 0.85)
	row.add_child(preview)

	# Tag de categoria (mini-pill)
	var cat_lbl := Label.new()
	cat_lbl.text = entry.category
	cat_lbl.add_theme_font_size_override("font_size", 10)
	cat_lbl.add_theme_color_override("font_color", category_color if seen else Color(0.35, 0.35, 0.4))
	cat_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	cat_lbl.add_theme_constant_override("outline_size", 1)
	cat_lbl.position = Vector2(46, 4)
	cat_lbl.size = Vector2(80, 12)
	row.add_child(cat_lbl)

	# Nome
	var name_lbl := Label.new()
	name_lbl.text = entry.display_name if seen else "??????"
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color.WHITE if seen else Color(0.45, 0.45, 0.5))
	name_lbl.position = Vector2(46, 14)
	name_lbl.size = Vector2(180, 16)
	row.add_child(name_lbl)

	# Descrição
	var desc_lbl := Label.new()
	desc_lbl.text = entry.description if seen else "Catalogue derrotando o inimigo durante uma run."
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85) if seen else Color(0.35, 0.35, 0.4))
	desc_lbl.position = Vector2(46, 28)
	desc_lbl.size = Vector2(PANEL_WIDTH - 96, 14)
	desc_lbl.clip_text = true
	row.add_child(desc_lbl)

	# Bio in-universe — aparece no tooltip ao hover (só pra entries vistas).
	if seen and entry.lore != "":
		row.tooltip_text = "%s\n\n— LOG DO GAMO —\n%s" % [
			entry.description, entry.lore
		]
		row.mouse_filter = Control.MOUSE_FILTER_STOP

	return row


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.18, 1.0)
	sb.border_color = Color("#e040fb")
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
