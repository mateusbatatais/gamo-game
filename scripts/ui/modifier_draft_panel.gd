## Painel de draft de modificadores — aparece quando o jogador clica em JOGAR
## na hub. Mostra 3 modificadores aleatórios + opção "Sem Modificador".
## Picking aplica o modifier e inicia a run.
class_name ModifierDraftPanel
extends CanvasLayer

const PANEL_WIDTH := 580
const PANEL_HEIGHT := 320
const CARD_W := 168
const CARD_H := 200

signal picked  ## emitido quando o jogador escolhe (incl. "sem modificador")

var _root: Control
var _draft_ids: Array[String] = []


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_empty()


func _build_empty() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)


func _build() -> void:
	for child in _root.get_children():
		child.queue_free()

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
	sb.bg_color = Color(0.06, 0.08, 0.12, 1.0)
	sb.border_color = Color("#e040fb")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var title := Label.new()
	title.text = "MODIFICADORES DE RUN"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#e040fb"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 6)
	title.size = Vector2(PANEL_WIDTH - 24, 22)
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Escolha 1 modificador (ou nenhum) pra esta run. Bônus + custo."
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	subtitle.position = Vector2(12, 28)
	subtitle.size = Vector2(PANEL_WIDTH - 24, 12)
	panel.add_child(subtitle)

	# 3 cards no centro
	var cards_hbox := HBoxContainer.new()
	cards_hbox.position = Vector2(12, 46)
	cards_hbox.size = Vector2(PANEL_WIDTH - 24, CARD_H)
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_hbox.add_theme_constant_override("separation", 12)
	panel.add_child(cards_hbox)

	for id in _draft_ids:
		cards_hbox.add_child(_make_card(id))

	# Botão "SEM MODIFICADOR" no rodapé
	var skip_btn := _make_button("JOGAR SEM MODIFICADOR")
	skip_btn.position = Vector2(PANEL_WIDTH * 0.5 - 130, PANEL_HEIGHT - 44)
	skip_btn.size = Vector2(260, 32)
	skip_btn.pressed.connect(_on_pick.bind(""))
	panel.add_child(skip_btn)


func _make_card(id: String) -> Button:
	var def: ModifierSystem.ModifierDef = ModifierSystem.get_def(id)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CARD_W, CARD_H)
	btn.focus_mode = Control.FOCUS_ALL
	btn.clip_contents = true

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	sb.border_color = def.accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color(def.accent.r * 0.15, def.accent.g * 0.15, def.accent.b * 0.15, 1.0)
	sb_focus.set_border_width_all(4)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)

	# Título grande no topo
	var title_lbl := Label.new()
	title_lbl.text = def.display_name
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", def.accent)
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	title_lbl.add_theme_constant_override("outline_size", 2)
	title_lbl.position = Vector2(8, 10)
	title_lbl.size = Vector2(CARD_W - 16, 22)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_child(title_lbl)

	# Linha separadora
	var sep := ColorRect.new()
	sep.color = Color(def.accent.r, def.accent.g, def.accent.b, 0.4)
	sep.position = Vector2(20, 38)
	sep.size = Vector2(CARD_W - 40, 1)
	btn.add_child(sep)

	# Bênção (+)
	var bless_lbl := Label.new()
	bless_lbl.text = "+  " + def.blessing
	bless_lbl.add_theme_font_size_override("font_size", 11)
	bless_lbl.add_theme_color_override("font_color", Color("#9bbc0f"))
	bless_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	bless_lbl.add_theme_constant_override("outline_size", 2)
	bless_lbl.position = Vector2(8, 60)
	bless_lbl.size = Vector2(CARD_W - 16, 40)
	bless_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_child(bless_lbl)

	# Maldição (–)
	var curse_lbl := Label.new()
	curse_lbl.text = "−  " + def.curse
	curse_lbl.add_theme_font_size_override("font_size", 11)
	curse_lbl.add_theme_color_override("font_color", Color("#ff5252"))
	curse_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	curse_lbl.add_theme_constant_override("outline_size", 2)
	curse_lbl.position = Vector2(8, 116)
	curse_lbl.size = Vector2(CARD_W - 16, 40)
	curse_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_child(curse_lbl)

	# Hint
	var hint_lbl := Label.new()
	hint_lbl.text = "[ESCOLHER]"
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.7, 0.72, 0.8))
	hint_lbl.position = Vector2(8, CARD_H - 22)
	hint_lbl.size = Vector2(CARD_W - 16, 14)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(hint_lbl)

	btn.pressed.connect(_on_pick.bind(id))
	return btn


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.18, 1.0)
	sb.border_color = Color("#bdbdbd")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color(0.15, 0.2, 0.3, 1.0)
	sb_focus.set_border_width_all(3)
	sb_focus.border_color = Color("#00e5ff")
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn


func _on_pick(id: String) -> void:
	ModifierSystem.set_active(id)
	Audio.play(Audio.Sfx.UI_CONFIRM)
	visible = false
	picked.emit()


func open() -> void:
	_draft_ids = ModifierSystem.draft(3)
	_build()
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		Audio.play(Audio.Sfx.UI_CANCEL)
		_on_pick("")  # cancelar = sem modificador
		get_viewport().set_input_as_handled()
