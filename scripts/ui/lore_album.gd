## Álbum de cartas (Lore Cards). Mostra todas as cartas em grid 3xN,
## com cartas não coletadas exibidas como silhuetas "???".
## Clicar em uma carta coletada abre detalhe expandido com o flavor text.
class_name LoreAlbum
extends CanvasLayer

const PANEL_WIDTH := 560
const PANEL_HEIGHT := 320
const CARD_W := 160
const CARD_H := 110
const COLS := 3

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
	sb.border_color = Color("#ffeb3b")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var title := Label.new()
	title.text = "ALBUM DE CARTAS"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#ffeb3b"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 8)
	title.size = Vector2(PANEL_WIDTH - 24, 24)
	panel.add_child(title)

	var ids := LoreCardRegistry.all_ids()
	var collected: int = 0
	for id in ids:
		if LoreCardRegistry.is_collected(id):
			collected += 1
	var counter := Label.new()
	counter.text = "%d / %d" % [collected, ids.size()]
	counter.add_theme_font_size_override("font_size", 14)
	counter.add_theme_color_override("font_color", Color("#9bbc0f"))
	counter.add_theme_color_override("font_outline_color", Color.BLACK)
	counter.add_theme_constant_override("outline_size", 2)
	counter.position = Vector2(PANEL_WIDTH - 110, 10)
	counter.size = Vector2(100, 18)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(counter)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12, 38)
	scroll.size = Vector2(PANEL_WIDTH - 24, PANEL_HEIGHT - 88)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)

	for id in ids:
		grid.add_child(_make_card(id))

	var close_btn := _make_button("FECHAR")
	close_btn.position = Vector2(PANEL_WIDTH * 0.5 - 70, PANEL_HEIGHT - 36)
	close_btn.size = Vector2(140, 28)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)


func _make_card(id: String) -> Button:
	var def: LoreCardRegistry.LoreCardDef = LoreCardRegistry.get_def(id)
	var collected: bool = LoreCardRegistry.is_collected(id)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CARD_W, CARD_H)
	btn.focus_mode = Control.FOCUS_ALL
	btn.clip_contents = true

	var border_color: Color = def.accent if collected else Color(0.25, 0.25, 0.28)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color(0.10, 0.12, 0.18, 1.0)
	sb_focus.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)

	# Header — raridade
	var rarity_lbl := Label.new()
	rarity_lbl.text = LoreCardRegistry.rarity_label(def.rarity) if collected else "???"
	rarity_lbl.add_theme_font_size_override("font_size", 10)
	rarity_lbl.add_theme_color_override(
		"font_color", LoreCardRegistry.rarity_color(def.rarity) if collected else Color(0.4, 0.4, 0.42)
	)
	rarity_lbl.position = Vector2(6, 4)
	rarity_lbl.size = Vector2(CARD_W - 12, 12)
	btn.add_child(rarity_lbl)

	# Subtítulo / contexto
	var sub_lbl := Label.new()
	sub_lbl.text = def.subtitle if collected else "BLOQUEADA"
	sub_lbl.add_theme_font_size_override("font_size", 9)
	sub_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8) if collected else Color(0.35, 0.35, 0.4))
	sub_lbl.position = Vector2(6, 16)
	sub_lbl.size = Vector2(CARD_W - 12, 10)
	btn.add_child(sub_lbl)

	# Título — destaca em accent
	var title_lbl := Label.new()
	title_lbl.text = def.title if collected else "?????"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override(
		"font_color", def.accent if collected else Color(0.45, 0.45, 0.48)
	)
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	title_lbl.add_theme_constant_override("outline_size", 2)
	title_lbl.position = Vector2(6, 28)
	title_lbl.size = Vector2(CARD_W - 12, 18)
	title_lbl.clip_text = true
	btn.add_child(title_lbl)

	# Body preview (3 linhas) — só se coletada
	var body_lbl := Label.new()
	body_lbl.text = def.body if collected else "Continue jogando pra desbloquear..."
	body_lbl.add_theme_font_size_override("font_size", 10)
	body_lbl.add_theme_color_override(
		"font_color", Color(0.85, 0.88, 0.95) if collected else Color(0.3, 0.3, 0.34)
	)
	body_lbl.position = Vector2(6, 48)
	body_lbl.size = Vector2(CARD_W - 12, CARD_H - 54)
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.clip_text = true
	btn.add_child(body_lbl)

	return btn


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
