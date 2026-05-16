## Hub "A Estante" — meta-progressão visual + seleção de Spirit/Era antes da run.
extends Control

const VIEWPORT_W := 640
const VIEWPORT_H := 360

var _selected_spirit_id: String = "pixel"
var _selected_era_id: String = "era_16bit"
var _spirit_card_buttons: Dictionary = {}
var _era_buttons: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(VIEWPORT_W, VIEWPORT_H)
	_selected_spirit_id = GameState.selected_spirit_id
	# 8-bit foi removido — força sempre 16-bit.
	_selected_era_id = "era_16bit"
	GameState.selected_era_id = "era_16bit"
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a14")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var title := Label.new()
	title.text = I18n.t("hub_title")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#ffeb3b"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(12, 6)
	title.size = Vector2(160, 24)
	add_child(title)

	var stats := Label.new()
	stats.text = _format_stats()
	stats.add_theme_font_size_override("font_size", 11)
	stats.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	stats.position = Vector2(VIEWPORT_W - 280, 10)
	stats.size = Vector2(270, 14)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(stats)

	_build_spirits_panel()
	_build_collection_panel()
	_build_buttons()


func _build_era_row() -> void:
	var label := Label.new()
	label.text = I18n.t("hub_era")
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#bdbdbd"))
	label.position = Vector2(12, 34)
	label.size = Vector2(40, 14)
	add_child(label)

	var hbox := HBoxContainer.new()
	hbox.position = Vector2(48, 32)
	hbox.size = Vector2(VIEWPORT_W - 60, 22)
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)

	for id in EraRegistry.all_ids():
		var btn := _make_era_button(id)
		hbox.add_child(btn)
		_era_buttons[id] = btn

	_refresh_era_selection()


func _make_era_button(era_id: String) -> Button:
	var def: EraRegistry.EraDef = EraRegistry.get_def(era_id)
	var unlocked := EraRegistry.is_unlocked(era_id)
	var btn := Button.new()
	btn.text = def.display_name if unlocked else (def.display_name + " (BLOQ)")
	btn.custom_minimum_size = Vector2(140, 20)
	btn.add_theme_font_size_override("font_size", 11)
	btn.disabled = not unlocked
	btn.tooltip_text = def.unlock_label if not unlocked else def.description

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.14, 1.0) if unlocked else Color(0.04, 0.04, 0.06, 1.0)
	sb.border_color = Color("#306230") if unlocked else Color(0.25, 0.25, 0.25)
	sb.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color("#1b3b1b")
	sb_focus.border_color = Color("#9bbc0f")
	sb_focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", Color("#9bbc0f"))
	if unlocked:
		btn.pressed.connect(_on_era_selected.bind(era_id))
	return btn


const SPIRITS_PANEL_POS := Vector2(12, 74)
const SPIRITS_PANEL_SIZE := Vector2(296, 232)
const SPIRIT_CARD_SIZE := Vector2(296, 232)


func _build_spirits_panel() -> void:
	var label := Label.new()
	label.text = I18n.t("hub_spirits")
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#9bbc0f"))
	label.position = Vector2(12, 56)
	label.size = Vector2(200, 16)
	add_child(label)

	# Grid funciona bem para 1 ou múltiplos spirits — só ajusta colunas conforme houver.
	var ids := SpiritRegistry.all_ids()
	var grid := GridContainer.new()
	grid.columns = max(1, min(2, ids.size()))
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.position = SPIRITS_PANEL_POS
	grid.size = SPIRITS_PANEL_SIZE
	add_child(grid)

	# Tamanho do card cresce quando há poucos spirits para evitar texto cortado.
	var per_row: int = grid.columns
	var card_w: int = int((SPIRITS_PANEL_SIZE.x - (per_row - 1) * 8) / per_row)
	var card_h: int = int(SPIRITS_PANEL_SIZE.y) if ids.size() <= per_row else int((SPIRITS_PANEL_SIZE.y - 8) / 2)
	var card_size := Vector2(card_w, card_h)

	for id in ids:
		var card := _make_spirit_card(id, card_size)
		grid.add_child(card)
		_spirit_card_buttons[id] = card

	_refresh_spirit_selection()


func _make_spirit_card(spirit_id: String, card_size: Vector2) -> Button:
	var def: SpiritRegistry.SpiritDef = SpiritRegistry.get_def(spirit_id)
	var unlocked: bool = SpiritRegistry.is_unlocked(spirit_id)
	var btn := Button.new()
	btn.custom_minimum_size = card_size
	btn.focus_mode = Control.FOCUS_ALL
	btn.disabled = not unlocked
	btn.clip_contents = true

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.14, 1.0) if unlocked else Color(0.04, 0.04, 0.06, 1.0)
	sb.border_color = Color("#306230") if unlocked else Color(0.25, 0.25, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_active := sb.duplicate() as StyleBoxFlat
	sb_active.bg_color = Color("#1b3b1b")
	sb_active.border_color = Color("#9bbc0f")
	sb_active.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", sb_active)
	btn.add_theme_stylebox_override("focus", sb_active)
	btn.add_theme_stylebox_override("pressed", sb_active)

	# Layout vertical (nome no topo, sprite no meio, descrição no fundo) que cabe em qualquer tamanho.
	var pad: int = 10
	var name_h: int = 22
	var desc_h: int = 56
	var sprite_band_h: int = int(card_size.y) - pad * 2 - name_h - desc_h - 8

	var name_label := Label.new()
	name_label.text = def.display_name if unlocked else I18n.t("hub_unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override(
		"font_color", Color("#9bbc0f") if unlocked else Color(0.5, 0.5, 0.5)
	)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.position = Vector2(pad, pad)
	name_label.size = Vector2(card_size.x - pad * 2, name_h)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.add_child(name_label)

	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.make_sprite(
		PackedStringArray(def.sprite_frames[0]),
		def.palette if unlocked else _grayscale(def.palette)
	)
	sprite.centered = true
	var scale_factor: float = clamp(min(card_size.x, sprite_band_h) / 32.0, 1.6, 3.5)
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(card_size.x / 2.0, pad + name_h + sprite_band_h / 2.0)
	btn.add_child(sprite)

	var bottom_y: int = int(card_size.y) - pad - desc_h
	if unlocked:
		var desc := Label.new()
		desc.text = def.description
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color.WHITE)
		desc.position = Vector2(pad, bottom_y)
		desc.size = Vector2(card_size.x - pad * 2, desc_h)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		desc.clip_text = true
		btn.add_child(desc)
		btn.pressed.connect(_on_spirit_selected.bind(spirit_id))
	else:
		var lock := Label.new()
		lock.text = I18n.t("hub_locked") + "\n" + def.unlock_label
		lock.add_theme_font_size_override("font_size", 10)
		lock.add_theme_color_override("font_color", Color(0.55, 0.4, 0.4))
		lock.position = Vector2(pad, bottom_y)
		lock.size = Vector2(card_size.x - pad * 2, desc_h)
		lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.clip_text = true
		btn.add_child(lock)

	return btn


func _grayscale(palette: Dictionary) -> Dictionary:
	var out := {}
	for key in palette.keys():
		var c: Color = palette[key]
		var lum: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
		out[key] = Color(lum * 0.35, lum * 0.35, lum * 0.35, c.a)
	return out


const COLLECTION_PANEL_X := 328  # VIEWPORT_W / 2 + 8
const COLLECTION_COLS := 4
const COLLECTION_CARD_SIZE := Vector2(72, 52)
const COLLECTION_H_SEP := 4
const COLLECTION_V_SEP := 4


func _build_collection_panel() -> void:
	var label := Label.new()
	label.text = I18n.t("hub_collection")
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#00e5ff"))
	label.position = Vector2(COLLECTION_PANEL_X, 56)
	label.size = Vector2(200, 16)
	add_child(label)

	var grid := GridContainer.new()
	grid.columns = COLLECTION_COLS
	grid.add_theme_constant_override("h_separation", COLLECTION_H_SEP)
	grid.add_theme_constant_override("v_separation", COLLECTION_V_SEP)
	grid.position = Vector2(COLLECTION_PANEL_X, 74)
	add_child(grid)

	for id in CartridgeRegistry.all_ids():
		var slot := _make_cartridge_slot(id)
		grid.add_child(slot)

	var total: int = CartridgeRegistry.all_ids().size()
	var collected: int = GameState.collected_cartridges.size()
	var count_label := Label.new()
	count_label.text = I18n.tf("hub_collected_count", [collected, total])
	count_label.add_theme_font_size_override("font_size", 11)
	count_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	count_label.position = Vector2(COLLECTION_PANEL_X, 296)
	count_label.size = Vector2(280, 16)
	add_child(count_label)


func _make_cartridge_slot(cartridge_id: String) -> Control:
	var def: CartridgeRegistry.CartridgeDef = CartridgeRegistry.get_def(cartridge_id)
	var collected: bool = cartridge_id in GameState.collected_cartridges
	var ctrl := Panel.new()
	ctrl.custom_minimum_size = COLLECTION_CARD_SIZE
	ctrl.clip_contents = true

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.14, 1.0)
	sb.border_color = (
		CartridgeRegistry.rarity_color(def.rarity) if collected
		else Color(0.2, 0.2, 0.2)
	)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	ctrl.add_theme_stylebox_override("panel", sb)

	var inner_w: float = COLLECTION_CARD_SIZE.x - 8
	var name_label := Label.new()
	name_label.text = def.display_name if collected else I18n.t("hub_unknown")
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override(
		"font_color",
		CartridgeRegistry.rarity_color(def.rarity) if collected else Color(0.4, 0.4, 0.4)
	)
	name_label.position = Vector2(4, 4)
	name_label.size = Vector2(inner_w, 28)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	name_label.clip_text = true
	ctrl.add_child(name_label)

	var type_label := Label.new()
	type_label.text = (
		I18n.t("lvl_up_weapon") if def.type == CartridgeRegistry.CartridgeType.WEAPON
		else I18n.t("lvl_up_passive")
	)
	type_label.add_theme_font_size_override("font_size", 8)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	type_label.position = Vector2(4, COLLECTION_CARD_SIZE.y - 14)
	type_label.size = Vector2(inner_w, 12)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctrl.add_child(type_label)

	return ctrl


func _build_buttons() -> void:
	# Header com label de tokens persistentes
	var tokens_lbl := Label.new()
	tokens_lbl.name = "TokensLabel"
	tokens_lbl.text = "TOKENS: %d" % GameState.memory_tokens
	tokens_lbl.add_theme_font_size_override("font_size", 12)
	tokens_lbl.add_theme_color_override("font_color", Color("#ffeb3b"))
	tokens_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	tokens_lbl.add_theme_constant_override("outline_size", 2)
	tokens_lbl.position = Vector2(VIEWPORT_W - 220, 34)
	tokens_lbl.size = Vector2(200, 16)
	tokens_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(tokens_lbl)
	# Conecta como método de membro — Godot auto-desconecta quando o Hub é
	# freed (mudança de cena). Lambda capturando o Label causaria use-after-free
	# quando inimigos morressem na arena e tokens_changed disparasse.
	EventBus.tokens_changed.connect(_on_tokens_changed)

	# 4 botões na barra inferior. Cada um 120 px de largura, separação 8 px.
	# Total: 4*120 + 3*8 = 504, cabe no viewport de 640.
	var btn_w := 120
	var sep := 8
	var hbox := HBoxContainer.new()
	hbox.anchor_top = 1.0
	hbox.anchor_bottom = 1.0
	hbox.anchor_left = 0.5
	hbox.anchor_right = 0.5
	hbox.position = Vector2(-256, -36)
	hbox.size = Vector2(512, 28)
	hbox.add_theme_constant_override("separation", sep)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	var play := _make_button(I18n.t("hub_play"), true, btn_w)
	play.pressed.connect(_on_play)
	hbox.add_child(play)

	var upgrades := _make_button("UPGRADES", false, btn_w)
	upgrades.pressed.connect(_on_open_upgrades)
	hbox.add_child(upgrades)

	var achievements := _make_button("CONQUISTAS", false, btn_w)
	achievements.pressed.connect(_on_open_achievements)
	hbox.add_child(achievements)

	var back := _make_button(I18n.t("hub_back"), false, btn_w)
	back.pressed.connect(_on_back)
	hbox.add_child(back)

	# Instancia o modal de upgrades + painel de conquistas (escondidos até clicar).
	var modal := UpgradesModal.new()
	modal.name = "UpgradesModal"
	add_child(modal)

	var ach_panel := AchievementsPanel.new()
	ach_panel.name = "AchievementsPanel"
	add_child(ach_panel)

	# Seta animada acompanhando o foco do menu.
	add_child(MenuCursor.new())

	play.grab_focus()


func _on_tokens_changed(total: int) -> void:
	var lbl := get_node_or_null("TokensLabel") as Label
	if lbl != null:
		lbl.text = "TOKENS: %d" % total


func _on_open_upgrades() -> void:
	var modal := get_node_or_null("UpgradesModal") as UpgradesModal
	if modal != null:
		modal.open()


func _on_open_achievements() -> void:
	var panel := get_node_or_null("AchievementsPanel") as AchievementsPanel
	if panel != null:
		panel.open()


func _make_button(text: String, primary: bool, width: int = 140) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, 28)
	# Fonte um pouco menor pra rótulos longos (CONQUISTAS) caberem em botões mais finos.
	var font_size: int = 14 if width <= 130 else 16
	btn.add_theme_font_size_override("font_size", font_size)

	var accent := Color("#9bbc0f") if primary else Color("#bdbdbd")
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.14, 1.0)
	sb.border_color = Color("#306230") if primary else Color(0.35, 0.35, 0.35)
	sb.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color("#1b3b1b") if primary else Color(0.2, 0.2, 0.2)
	sb_focus.border_color = accent
	sb_focus.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", accent)
	return btn


func _format_stats() -> String:
	var best_s := int(GameState.best_run_time)
	var best_str := "%d:%02d" % [best_s / 60, best_s % 60]
	return "%s %s   %s %d   %s %d" % [
		I18n.t("hub_best_time"), best_str,
		I18n.t("hub_kills"), GameState.total_kills,
		I18n.t("hub_runs"), GameState.total_runs,
	]


func _on_era_selected(era_id: String) -> void:
	if not EraRegistry.is_unlocked(era_id):
		return
	_selected_era_id = era_id
	GameState.selected_era_id = era_id
	GameState.save_progress()
	_refresh_era_selection()


func _refresh_era_selection() -> void:
	for id in _era_buttons.keys():
		var btn: Button = _era_buttons[id]
		if id == _selected_era_id:
			btn.modulate = Color(1.3, 1.3, 1.3, 1.0)
		else:
			btn.modulate = Color.WHITE


func _on_spirit_selected(spirit_id: String) -> void:
	if not SpiritRegistry.is_unlocked(spirit_id):
		return
	_selected_spirit_id = spirit_id
	GameState.selected_spirit_id = spirit_id
	GameState.save_progress()
	_refresh_spirit_selection()


func _refresh_spirit_selection() -> void:
	for id in _spirit_card_buttons.keys():
		var btn: Button = _spirit_card_buttons[id]
		if id == _selected_spirit_id:
			btn.modulate = Color(1.3, 1.3, 1.3, 1.0)
		else:
			btn.modulate = Color.WHITE


func _on_play() -> void:
	SceneRouter.go_to_arena()


func _on_back() -> void:
	SceneRouter.go_to_main_menu()
