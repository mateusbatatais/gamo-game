## Painel da Talent Tree na hub. Mostra os 6 chips, nível atual, custo do
## próximo, e botão pra comprar. Custa tokens (que também são usados em upgrades).
class_name TalentTreePanel
extends CanvasLayer

const PANEL_WIDTH := 580
const PANEL_HEIGHT := 340

var _root: Control


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_empty()
	EventBus.tokens_changed.connect(_on_tokens_changed)


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
	sb.bg_color = Color(0.07, 0.09, 0.14, 1.0)
	sb.border_color = Color("#00e5ff")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var title := Label.new()
	title.text = "TALENT CHIPS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#00e5ff"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 8)
	title.size = Vector2(PANEL_WIDTH - 24, 22)
	panel.add_child(title)

	# Token counter à direita
	var tokens_lbl := Label.new()
	tokens_lbl.name = "TokensLabel"
	tokens_lbl.text = "TOKENS: %d" % GameState.memory_tokens
	tokens_lbl.add_theme_font_size_override("font_size", 12)
	tokens_lbl.add_theme_color_override("font_color", Color("#ffeb3b"))
	tokens_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	tokens_lbl.add_theme_constant_override("outline_size", 2)
	tokens_lbl.position = Vector2(PANEL_WIDTH - 160, 12)
	tokens_lbl.size = Vector2(148, 16)
	tokens_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(tokens_lbl)

	var prestige_lbl := Label.new()
	if GameState.prestige_level > 0:
		prestige_lbl.text = "PRESTIGE NG+%d" % GameState.prestige_level
		prestige_lbl.add_theme_color_override("font_color", Color("#e040fb"))
	else:
		prestige_lbl.text = "Permanente — aplicado em toda run."
		prestige_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	prestige_lbl.add_theme_font_size_override("font_size", 10)
	prestige_lbl.position = Vector2(12, 30)
	prestige_lbl.size = Vector2(PANEL_WIDTH - 24, 12)
	panel.add_child(prestige_lbl)

	# Grid 3x2 dos talents.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(12, 48)
	grid.size = Vector2(PANEL_WIDTH - 24, PANEL_HEIGHT - 100)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	panel.add_child(grid)

	for id in TalentTree.all_ids():
		grid.add_child(_make_card(id))

	var close_btn := _make_button("FECHAR")
	close_btn.position = Vector2(PANEL_WIDTH * 0.5 - 70, PANEL_HEIGHT - 36)
	close_btn.size = Vector2(140, 28)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)


func _make_card(id: String) -> Button:
	var def: TalentTree.TalentDef = TalentTree.get_def(id)
	var lvl: int = TalentTree.get_level(id)
	var cost: int = TalentTree.next_cost(id)
	var maxed: bool = cost < 0
	var can_buy: bool = (not maxed) and GameState.memory_tokens >= cost

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(178, 118)
	btn.focus_mode = Control.FOCUS_ALL
	btn.disabled = maxed or not can_buy
	btn.clip_contents = true

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	sb.border_color = def.accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color(def.accent.r * 0.15, def.accent.g * 0.15, def.accent.b * 0.15, 1.0)
	sb_focus.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)

	# Nome
	var name_lbl := Label.new()
	name_lbl.text = def.display_name
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", def.accent)
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	name_lbl.add_theme_constant_override("outline_size", 2)
	name_lbl.position = Vector2(8, 6)
	name_lbl.size = Vector2(162, 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(name_lbl)

	# Pips de nível
	for i in def.max_level:
		var pip := ColorRect.new()
		pip.color = def.accent if i < lvl else Color(0.2, 0.22, 0.28)
		pip.position = Vector2(8 + i * 56, 24)
		pip.size = Vector2(52, 5)
		btn.add_child(pip)

	# Descrição
	var desc := Label.new()
	desc.text = TalentTree.description_for(id)
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	desc.position = Vector2(8, 36)
	desc.size = Vector2(162, 50)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_child(desc)

	# Custo
	var cost_lbl := Label.new()
	if maxed:
		cost_lbl.text = "MAX"
		cost_lbl.add_theme_color_override("font_color", Color("#9bbc0f"))
	else:
		cost_lbl.text = "%d tokens" % cost
		cost_lbl.add_theme_color_override(
			"font_color", Color("#ffeb3b") if can_buy else Color(0.55, 0.5, 0.4)
		)
	cost_lbl.add_theme_font_size_override("font_size", 11)
	cost_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	cost_lbl.add_theme_constant_override("outline_size", 2)
	cost_lbl.position = Vector2(8, 96)
	cost_lbl.size = Vector2(162, 14)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(cost_lbl)

	if not maxed and can_buy:
		btn.pressed.connect(_on_buy.bind(id))
	return btn


func _on_buy(id: String) -> void:
	if TalentTree.purchase(id):
		Audio.play(Audio.Sfx.UI_CONFIRM)
		_build()
	else:
		Audio.play(Audio.Sfx.UI_ERROR)


func _on_tokens_changed(_total: int) -> void:
	if visible:
		_build()


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
