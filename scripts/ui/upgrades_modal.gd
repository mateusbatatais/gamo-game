## Modal de upgrades permanentes — gasta Tokens de Memória pra subir stats
## que se aplicam em todas as runs futuras. Aberto pelo botão UPGRADES na hub.
class_name UpgradesModal
extends CanvasLayer

const ROW_HEIGHT := 44
const PANEL_WIDTH := 480
const PANEL_HEIGHT := 320

var _root: Control
var _panel: Panel
var _list: VBoxContainer
var _tokens_label: Label
var _row_buttons: Dictionary = {}  # upgrade_id -> {button, name_lbl, level_lbl, cost_lbl}


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	EventBus.tokens_changed.connect(_on_tokens_changed)


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

	_panel = Panel.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.position = Vector2(-PANEL_WIDTH * 0.5, -PANEL_HEIGHT * 0.5)
	_panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.18, 1.0)
	sb.border_color = Color("#00e5ff")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(_panel)

	var title := Label.new()
	title.text = "UPGRADES PERMANENTES"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#00e5ff"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 8)
	title.size = Vector2(PANEL_WIDTH - 24, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_panel.add_child(title)

	_tokens_label = Label.new()
	_tokens_label.add_theme_font_size_override("font_size", 14)
	_tokens_label.add_theme_color_override("font_color", Color("#ffeb3b"))
	_tokens_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_tokens_label.add_theme_constant_override("outline_size", 2)
	_tokens_label.position = Vector2(12, 32)
	_tokens_label.size = Vector2(PANEL_WIDTH - 24, 18)
	_tokens_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_panel.add_child(_tokens_label)

	# ScrollContainer pra acomodar todos os upgrades mesmo que ultrapassem a altura visível.
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12, 56)
	scroll.size = Vector2(PANEL_WIDTH - 24, PANEL_HEIGHT - 100)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	for id in UpgradeRegistry.all_ids():
		var row := _make_row(id)
		_list.add_child(row)

	var close_btn := _make_button("FECHAR", true)
	close_btn.position = Vector2(PANEL_WIDTH * 0.5 - 70, PANEL_HEIGHT - 36)
	close_btn.size = Vector2(140, 28)
	close_btn.pressed.connect(close)
	_panel.add_child(close_btn)


func _make_row(upgrade_id: String) -> Control:
	var def: UpgradeRegistry.UpgradeDef = UpgradeRegistry.get_def(upgrade_id)
	var row := Panel.new()
	row.custom_minimum_size = Vector2(PANEL_WIDTH - 24, ROW_HEIGHT)
	var rb := StyleBoxFlat.new()
	rb.bg_color = Color(0.04, 0.06, 0.10, 1.0)
	rb.border_color = Color(0.2, 0.3, 0.4)
	rb.set_border_width_all(1)
	rb.set_corner_radius_all(3)
	row.add_theme_stylebox_override("panel", rb)

	var name_lbl := Label.new()
	name_lbl.text = def.display_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.position = Vector2(8, 4)
	name_lbl.size = Vector2(180, 16)
	row.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = def.description
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	desc_lbl.position = Vector2(8, 22)
	desc_lbl.size = Vector2(280, 14)
	desc_lbl.clip_text = true
	row.add_child(desc_lbl)

	var level_lbl := Label.new()
	level_lbl.add_theme_font_size_override("font_size", 12)
	level_lbl.add_theme_color_override("font_color", Color("#9bbc0f"))
	level_lbl.position = Vector2(300, 8)
	level_lbl.size = Vector2(70, 16)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(level_lbl)

	var buy_btn := _make_button("", false)
	buy_btn.position = Vector2(370, 8)
	buy_btn.size = Vector2(80, 28)
	buy_btn.add_theme_font_size_override("font_size", 12)
	buy_btn.pressed.connect(_buy_upgrade.bind(upgrade_id))
	row.add_child(buy_btn)

	_row_buttons[upgrade_id] = {
		"button": buy_btn,
		"level_lbl": level_lbl,
	}
	return row


func _make_button(text: String, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	var accent: Color = Color("#9bbc0f") if primary else Color("#00e5ff")
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.18, 1.0)
	sb.border_color = accent
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
	btn.add_theme_color_override("font_focus_color", accent)
	return btn


func open() -> void:
	visible = true
	_refresh_all()


func close() -> void:
	visible = false


func _refresh_all() -> void:
	_tokens_label.text = "TOKENS: %d" % GameState.memory_tokens
	for id in _row_buttons.keys():
		_refresh_row(id)


func _refresh_row(id: String) -> void:
	var def: UpgradeRegistry.UpgradeDef = UpgradeRegistry.get_def(id)
	var data: Dictionary = _row_buttons[id]
	var lvl: int = GameState.get_upgrade_level(id)
	var level_lbl: Label = data["level_lbl"]
	level_lbl.text = "Nv %d/%d" % [lvl, def.max_level]
	var btn: Button = data["button"]
	if lvl >= def.max_level:
		btn.text = "MAX"
		btn.disabled = true
	else:
		var cost: int = UpgradeRegistry.cost_for_next(id)
		btn.text = "%d T" % cost
		btn.disabled = GameState.memory_tokens < cost


func _buy_upgrade(id: String) -> void:
	var cost: int = UpgradeRegistry.cost_for_next(id)
	if cost < 0:
		Audio.play(Audio.Sfx.UI_ERROR)
		return
	if not GameState.spend_tokens(cost):
		Audio.play(Audio.Sfx.UI_ERROR)
		return
	GameState.increment_upgrade(id)
	Audio.play(Audio.Sfx.UI_SELECT)
	_refresh_all()


func _on_tokens_changed(_total: int) -> void:
	if visible:
		_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		Audio.play(Audio.Sfx.UI_CANCEL)
		close()
		get_viewport().set_input_as_handled()
