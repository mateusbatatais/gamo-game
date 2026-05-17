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
	Music.play_menu()
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

	# Stats removidos do topo da hub — já aparecem no menu principal.
	# Em vez disso, mostra só "PRESTIGE NG+X" se aplicável (compacto).
	if GameState.prestige_level > 0:
		var prestige := Label.new()
		prestige.text = "★ NG+%d" % GameState.prestige_level
		prestige.add_theme_font_size_override("font_size", 12)
		prestige.add_theme_color_override("font_color", Color("#e040fb"))
		prestige.add_theme_color_override("font_outline_color", Color.BLACK)
		prestige.add_theme_constant_override("outline_size", 2)
		prestige.position = Vector2(180, 10)
		prestige.size = Vector2(80, 16)
		add_child(prestige)

	_build_spirits_panel()
	_build_collection_panel()
	_build_npcs()
	_build_buttons()


func _build_npcs() -> void:
	# 3 NPCs como avatares compactos no canto superior direito.
	# Sem labels — só ícone colorido + tooltip com nome (clique abre dialog).
	var npcs := HubNpcs.new()
	npcs.position = Vector2(VIEWPORT_W - 110, 6)
	npcs.size = Vector2(98, 22)
	add_child(npcs)


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
const SPIRITS_PANEL_SIZE := Vector2(240, 232)
const SPIRIT_CARD_SIZE := Vector2(240, 232)


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

	# Layout: nome (22) + sprite_preview (96) + skin_label (14) + skins_row (52) + stats (32)
	var pad: int = 8
	var name_h: int = 22
	var sprite_h: int = 96
	var skin_lbl_h: int = 14
	var skins_h: int = 52

	# Nome do personagem
	var name_label := Label.new()
	name_label.text = def.display_name if unlocked else I18n.t("hub_unknown")
	name_label.add_theme_font_size_override("font_size", 18)
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

	# Sprite preview com paleta da skin ativa
	var preview_palette: Dictionary = SkinRegistry.active_palette()
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.make_sprite(
		PackedStringArray(def.sprite_frames[0]),
		preview_palette if unlocked else _grayscale(preview_palette)
	)
	sprite.centered = true
	sprite.scale = Vector2(3.0, 3.0)
	sprite.position = Vector2(card_size.x / 2.0, pad + name_h + sprite_h / 2.0)
	sprite.name = "PreviewSprite"
	btn.add_child(sprite)

	if not unlocked:
		return btn

	# Header "SKIN" + linha de thumbnails
	var skin_lbl_y: int = pad + name_h + sprite_h
	var skin_label := Label.new()
	skin_label.text = "SKIN"
	skin_label.add_theme_font_size_override("font_size", 10)
	skin_label.add_theme_color_override("font_color", Color("#00e5ff"))
	skin_label.add_theme_color_override("font_outline_color", Color.BLACK)
	skin_label.add_theme_constant_override("outline_size", 2)
	skin_label.position = Vector2(pad, skin_lbl_y)
	skin_label.size = Vector2(card_size.x - pad * 2, skin_lbl_h)
	skin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(skin_label)

	# Linha de thumbnails de skin
	var skins := SkinRegistry.all_ids()
	var skin_count := skins.size()
	var thumb_w: int = 30
	var thumb_gap: int = 4
	var total_w: int = skin_count * thumb_w + (skin_count - 1) * thumb_gap
	var skins_y: int = skin_lbl_y + skin_lbl_h
	var start_x: int = int((card_size.x - total_w) / 2)
	for i in skin_count:
		var skin_id: String = skins[i]
		var thumb := _make_skin_thumb(skin_id, sprite, name_label)
		thumb.position = Vector2(start_x + i * (thumb_w + thumb_gap), skins_y)
		thumb.size = Vector2(thumb_w, skins_h - 6)
		btn.add_child(thumb)

	# Rodapé pequeno com descrição da skin atual
	var stats_y: int = skins_y + skins_h
	var info := Label.new()
	info.name = "SkinInfo"
	info.add_theme_font_size_override("font_size", 10)
	info.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	info.add_theme_color_override("font_outline_color", Color.BLACK)
	info.add_theme_constant_override("outline_size", 2)
	info.position = Vector2(pad, stats_y)
	info.size = Vector2(card_size.x - pad * 2, card_size.y - stats_y - 2)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.clip_text = true
	btn.add_child(info)
	_refresh_skin_info(info)

	btn.pressed.connect(_on_spirit_selected.bind(spirit_id))
	return btn


## Constrói um botão-thumbnail de skin com mini-sprite + nome.
func _make_skin_thumb(skin_id: String, preview_sprite: Sprite2D, name_label: Label) -> Button:
	var def: SkinRegistry.SkinDef = SkinRegistry.get_def(skin_id)
	var unlocked: bool = SkinRegistry.is_unlocked(skin_id)
	var active: bool = GameState.current_skin_id == skin_id
	var thumb := Button.new()
	thumb.focus_mode = Control.FOCUS_ALL
	thumb.disabled = not unlocked
	thumb.toggle_mode = false

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 1.0)
	if active:
		sb.border_color = Color("#ffeb3b")
		sb.set_border_width_all(2)
	elif unlocked:
		sb.border_color = Color(0.35, 0.4, 0.5)
		sb.set_border_width_all(1)
	else:
		sb.border_color = Color(0.2, 0.2, 0.22)
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	thumb.add_theme_stylebox_override("normal", sb)
	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.border_color = Color("#00e5ff")
	sb_focus.set_border_width_all(2)
	thumb.add_theme_stylebox_override("hover", sb_focus)
	thumb.add_theme_stylebox_override("focus", sb_focus)

	# Mini-sprite (preview da skin) ou cadeado se bloqueada
	var mini := Sprite2D.new()
	if unlocked:
		mini.texture = PixelArt.make_sprite(
			PackedStringArray(Sprites.GAMO_T1_IDLE[0]),
			def.palette
		)
		mini.scale = Vector2(1.0, 1.0)
	else:
		mini.texture = PixelArt.make_sprite(
			PackedStringArray(Sprites.GAMO_T1_IDLE[0]),
			_grayscale(def.palette)
		)
		mini.scale = Vector2(1.0, 1.0)
		mini.modulate = Color(0.5, 0.5, 0.55)
	mini.centered = true
	mini.position = Vector2(15, 22)
	thumb.add_child(mini)

	if unlocked:
		thumb.pressed.connect(_on_skin_picked.bind(skin_id, preview_sprite, name_label, thumb))
	else:
		# Tooltip mostra unlock hint quando bloqueada.
		thumb.tooltip_text = def.unlock_hint
	return thumb


func _on_skin_picked(skin_id: String, preview_sprite: Sprite2D, _name_label: Label, _thumb: Button) -> void:
	if not SkinRegistry.is_unlocked(skin_id):
		Audio.play(Audio.Sfx.UI_ERROR)
		return
	GameState.current_skin_id = skin_id
	GameState.save_progress()
	Audio.play(Audio.Sfx.UI_SELECT)
	# Atualiza preview com nova paleta
	preview_sprite.texture = PixelArt.make_sprite(
		PackedStringArray(SpiritRegistry.get_def("pixel").sprite_frames[0]),
		SkinRegistry.active_palette()
	)
	# Refaz o card pra atualizar borda do thumb ativo + info.
	_rebuild_spirit_card()


func _rebuild_spirit_card() -> void:
	# Limpa o GridContainer atual e reconstrói.
	for child in get_children():
		if child is GridContainer:
			for c in child.get_children():
				c.queue_free()
			# Aguarda 1 frame pra free completar antes de reconstruir.
			call_deferred("_build_spirits_panel_inplace", child)
			return


func _build_spirits_panel_inplace(grid: GridContainer) -> void:
	var ids := SpiritRegistry.all_ids()
	var card_w: int = int((SPIRITS_PANEL_SIZE.x - (grid.columns - 1) * 8) / grid.columns)
	var card_h: int = int(SPIRITS_PANEL_SIZE.y) if ids.size() <= grid.columns else int((SPIRITS_PANEL_SIZE.y - 8) / 2)
	var card_size := Vector2(card_w, card_h)
	for id in ids:
		var card := _make_spirit_card(id, card_size)
		grid.add_child(card)
		_spirit_card_buttons[id] = card


func _refresh_skin_info(info: Label) -> void:
	var def: SkinRegistry.SkinDef = SkinRegistry.get_def(GameState.current_skin_id)
	if def == null:
		info.text = ""
		return
	# Só o nome da skin — descrição completa fica no tooltip (não polui o card).
	info.text = "SKIN: %s" % def.display_name.to_upper()
	info.tooltip_text = def.description


func _grayscale(palette: Dictionary) -> Dictionary:
	var out := {}
	for key in palette.keys():
		var c: Color = palette[key]
		var lum: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
		out[key] = Color(lum * 0.35, lum * 0.35, lum * 0.35, c.a)
	return out


const COLLECTION_PANEL_X := 264  ## logo após o painel de spirits (240 wide + 12 margin)
const COLLECTION_PANEL_W := VIEWPORT_W - COLLECTION_PANEL_X - 12  ## 364 wide
const COLLECTION_COLS := 4
const COLLECTION_CARD_SIZE := Vector2(84, 56)  ## maior pra cabeçalho não cortar
const COLLECTION_H_SEP := 4
const COLLECTION_V_SEP := 4
const COLLECTION_SCROLL_HEIGHT := 226  ## de y=74 até y=300


func _build_collection_panel() -> void:
	var label := Label.new()
	label.text = I18n.t("hub_collection")
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#00e5ff"))
	label.position = Vector2(COLLECTION_PANEL_X, 56)
	label.size = Vector2(200, 16)
	add_child(label)

	# Contador agora vai pro CANTO DIREITO da label, em vez de overlapping o grid.
	var total: int = CartridgeRegistry.all_ids().size()
	var collected: int = GameState.collected_cartridges.size()
	var count_label := Label.new()
	count_label.text = I18n.tf("hub_collected_count", [collected, total])
	count_label.add_theme_font_size_override("font_size", 11)
	count_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	count_label.position = Vector2(COLLECTION_PANEL_X + 80, 58)
	count_label.size = Vector2(COLLECTION_PANEL_W - 80, 14)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(count_label)

	# ScrollContainer com altura fixa — colecao cresce verticalmente sem invadir
	# a barra de botões nem o counter.
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(COLLECTION_PANEL_X, 74)
	scroll.size = Vector2(COLLECTION_PANEL_W, COLLECTION_SCROLL_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = COLLECTION_COLS
	grid.add_theme_constant_override("h_separation", COLLECTION_H_SEP)
	grid.add_theme_constant_override("v_separation", COLLECTION_V_SEP)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for id in CartridgeRegistry.all_ids():
		var slot := _make_cartridge_slot(id)
		grid.add_child(slot)


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
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override(
		"font_color",
		CartridgeRegistry.rarity_color(def.rarity) if collected else Color(0.4, 0.4, 0.4)
	)
	name_label.position = Vector2(4, 4)
	name_label.size = Vector2(inner_w, 32)
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
	type_label.add_theme_font_size_override("font_size", 9)
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

	# 7 botões na barra inferior. Cada um 78 px de largura, separação 5 px.
	# Total: 7*78 + 6*5 = 576, cabe no viewport de 640.
	var btn_w := 78
	var sep := 5
	var hbox := HBoxContainer.new()
	hbox.anchor_top = 1.0
	hbox.anchor_bottom = 1.0
	hbox.anchor_left = 0.5
	hbox.anchor_right = 0.5
	hbox.position = Vector2(-288, -36)
	hbox.size = Vector2(576, 28)
	hbox.add_theme_constant_override("separation", sep)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	var play := _make_button(I18n.t("hub_play"), true, btn_w)
	play.pressed.connect(_on_play)
	hbox.add_child(play)

	var upgrades := _make_button("UPGRADES", false, btn_w)
	upgrades.pressed.connect(_on_open_upgrades)
	hbox.add_child(upgrades)

	var talents := _make_button("TALENTOS", false, btn_w)
	talents.pressed.connect(_on_open_talents)
	hbox.add_child(talents)

	var archive := _make_button("ARQUIVO", false, btn_w)
	archive.pressed.connect(_on_open_codex)
	hbox.add_child(archive)

	var album := _make_button("ALBUM", false, btn_w)
	album.pressed.connect(_on_open_album)
	hbox.add_child(album)

	var achievements := _make_button("CONQ.", false, btn_w)
	achievements.pressed.connect(_on_open_achievements)
	hbox.add_child(achievements)

	var back := _make_button(I18n.t("hub_back"), false, btn_w)
	back.pressed.connect(_on_back)
	hbox.add_child(back)

	# Instancia o modal de upgrades + painel de conquistas + codex + album (escondidos até clicar).
	var modal := UpgradesModal.new()
	modal.name = "UpgradesModal"
	add_child(modal)

	var ach_panel := AchievementsPanel.new()
	ach_panel.name = "AchievementsPanel"
	add_child(ach_panel)

	var codex := CodexPanel.new()
	codex.name = "CodexPanel"
	add_child(codex)

	var album_panel := LoreAlbum.new()
	album_panel.name = "LoreAlbum"
	add_child(album_panel)

	# Toast pra notificar quando uma nova carta é desbloqueada durante a sessão.
	var toast := LoreCardToast.new()
	toast.name = "LoreCardToast"
	add_child(toast)

	# Painel de modificadores — aparece quando o jogador clica JOGAR.
	var draft := ModifierDraftPanel.new()
	draft.name = "ModifierDraftPanel"
	draft.picked.connect(_on_modifier_picked)
	add_child(draft)

	# Painel da Talent Tree (meta-progressão permanente).
	var talents_panel := TalentTreePanel.new()
	talents_panel.name = "TalentTreePanel"
	add_child(talents_panel)

	# Seta animada acompanhando o foco do menu.
	add_child(MenuCursor.new())

	play.grab_focus()


func _on_open_codex() -> void:
	var panel := get_node_or_null("CodexPanel") as CodexPanel
	if panel != null:
		panel.open()


func _on_open_album() -> void:
	var panel := get_node_or_null("LoreAlbum") as LoreAlbum
	if panel != null:
		panel.open()


func _on_open_talents() -> void:
	var panel := get_node_or_null("TalentTreePanel") as TalentTreePanel
	if panel != null:
		panel.open()


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
	# Garante que uma run iniciada pela hub não seja contabilizada como diária
	# caso o jogador tenha clicado em "JOGAR AGORA" e voltado sem terminar.
	DailyRun.clear_daily_flag()
	# Abre o draft de modificadores antes da run.
	var draft := get_node_or_null("ModifierDraftPanel") as ModifierDraftPanel
	if draft != null:
		draft.open()
	else:
		SceneRouter.go_to_arena()


func _on_modifier_picked() -> void:
	SceneRouter.go_to_arena()


func _on_back() -> void:
	SceneRouter.go_to_main_menu()
