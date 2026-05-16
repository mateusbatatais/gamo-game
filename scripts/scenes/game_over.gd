## Tela final da run: vitória ou derrota com base em GameState.last_run_victory.
extends Control


func _ready() -> void:
	_build()


func _build() -> void:
	var victory := GameState.last_run_victory
	var bg := ColorRect.new()
	bg.color = Color("#0a1f0a") if victory else Color("#1a0000")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var stripes := ColorRect.new()
	stripes.color = Color(0, 1, 0.3, 0.04) if victory else Color(1, 0, 0.5, 0.04)
	stripes.anchor_right = 1.0
	stripes.anchor_bottom = 1.0
	add_child(stripes)

	var title := Label.new()
	title.text = I18n.t("go_victory") if victory else I18n.t("go_defeat")
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#9bbc0f") if victory else Color("#ff0080"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 4)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.position = Vector2(-140, 56)
	title.size = Vector2(280, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var subtitle := TypewriterLabel.new()
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#9bbc0f") if victory else Color("#ff0080"))
	subtitle.anchor_left = 0.5
	subtitle.anchor_right = 0.5
	subtitle.position = Vector2(-140, 104)
	subtitle.size = Vector2(280, 16)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)
	var sub_text: String = I18n.t("go_victory_sub") if victory else I18n.t("go_defeat_sub")
	subtitle.type_text(sub_text, 0.04)

	if victory:
		var reward := Label.new()
		reward.text = I18n.tf("go_reward", [_reward_name_for_era()])
		reward.add_theme_font_size_override("font_size", 12)
		reward.add_theme_color_override("font_color", Color("#ffc107"))
		reward.anchor_left = 0.5
		reward.anchor_right = 0.5
		reward.position = Vector2(-140, 122)
		reward.size = Vector2(280, 14)
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(reward)

	# Painel de stats — grid 2 colunas com métricas da run
	_build_stats_panel(victory)

	# Botões em linha horizontal (REJOGAR + MENU) acima do CTA.
	# Posição ajustada pra dar folga pro CTA no rodapé sem sobreposição.
	var hbox := HBoxContainer.new()
	hbox.anchor_left = 0.5
	hbox.anchor_right = 0.5
	hbox.position = Vector2(-150, 280)
	hbox.size = Vector2(300, 28)
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	var retry := _make_button(I18n.t("go_retry"), victory)
	retry.pressed.connect(_on_retry)
	hbox.add_child(retry)

	var menu := _make_button(I18n.t("go_menu"), victory)
	menu.pressed.connect(_on_menu)
	hbox.add_child(menu)

	# CTA Gamo no rodapé — barra horizontal abaixo dos botões.
	_build_gamo_cta()

	add_child(MenuCursor.new())
	retry.grab_focus()


func _build_stats_panel(victory: bool) -> void:
	# Painel central — 6 métricas, duas colunas (label + value).
	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.position = Vector2(-160, 138)
	panel.size = Vector2(320, 134)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.9)
	sb.border_color = Color("#9bbc0f") if victory else Color("#ff5252")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var stats := _collect_stats()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(14, 8)
	grid.size = Vector2(292, 118)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 1)
	panel.add_child(grid)
	for pair in stats:
		grid.add_child(_make_stat_label(pair[0], false))
		grid.add_child(_make_stat_label(pair[1], true))


func _collect_stats() -> Array:
	var s := int(GameState.run_time)
	var time_str := "%d:%02d" % [s / 60, s % 60]
	return [
		["TEMPO", time_str],
		["KILLS", str(GameState.run_kills)],
		["DANO CAUSADO", str(GameState.last_run_damage_dealt)],
		["COMBO MÁX", "x%d" % GameState.last_run_max_combo],
		["TOKENS GANHOS", "%d T" % GameState.last_run_tokens_earned],
		["TOKENS NO TOTAL", "%d T" % GameState.memory_tokens],
	]


func _make_stat_label(text: String, is_value: bool) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	if is_value:
		lbl.add_theme_color_override("font_color", Color("#ffeb3b"))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.custom_minimum_size = Vector2(138, 18)
	return lbl


## CTA "Conheça gamo.games" — barra horizontal no rodapé inferior.
## mouse_filter = IGNORE em tudo pra NUNCA roubar cliques dos botões acima.
func _build_gamo_cta() -> void:
	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	# 4px de margem inferior + sobe alguns px pra não encostar nos botões.
	panel.position = Vector2(-240, -50)
	panel.size = Vector2(480, 44)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # passa cliques adiante
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.95)
	sb.border_color = Color("#ffeb3b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	# "QR" decorativo à esquerda, 32x32 — quadrado e bem visível.
	var qr_tex := _make_fake_qr_texture()
	var qr := TextureRect.new()
	qr.texture = qr_tex
	qr.position = Vector2(6, 6)
	qr.size = Vector2(32, 32)
	qr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	qr.stretch_mode = TextureRect.STRETCH_SCALE
	qr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	qr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(qr)

	# Linha 1: chamada amarela
	var caption := Label.new()
	caption.text = "CURTE COLECIONAR GAMES DE VERDADE?"
	caption.add_theme_font_size_override("font_size", 11)
	caption.add_theme_color_override("font_color", Color("#ffeb3b"))
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 2)
	caption.position = Vector2(46, 4)
	caption.size = Vector2(430, 14)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(caption)

	# Linha 2: gamo.games em ciano grande + chamada à direita
	var url := Label.new()
	url.text = "gamo.games"
	url.add_theme_font_size_override("font_size", 18)
	url.add_theme_color_override("font_color", Color("#00e5ff"))
	url.add_theme_color_override("font_outline_color", Color.BLACK)
	url.add_theme_constant_override("outline_size", 3)
	url.position = Vector2(46, 18)
	url.size = Vector2(180, 22)
	url.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	url.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(url)

	var hint := Label.new()
	hint.text = "→ Conheça a plataforma"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 2)
	hint.position = Vector2(232, 20)
	hint.size = Vector2(240, 18)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hint)


## Gera uma textura 21x21 procedural que LEMBRA um QR — quadrados de canto + ruído
## pseudo-aleatório com seed fixa pro padrão ser estável entre runs.
func _make_fake_qr_texture() -> ImageTexture:
	var size := 21
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var black := Color.BLACK
	var white := Color.WHITE
	img.fill(white)
	# Marcadores de canto (3 cantos: top-left, top-right, bottom-left)
	for corner in [Vector2i(0, 0), Vector2i(size - 7, 0), Vector2i(0, size - 7)]:
		for dy in 7:
			for dx in 7:
				var on_border: bool = dx == 0 or dy == 0 or dx == 6 or dy == 6
				var inner: bool = dx >= 2 and dx <= 4 and dy >= 2 and dy <= 4
				if on_border or inner:
					img.set_pixel(corner.x + dx, corner.y + dy, black)
	# Padrão pseudo-random no resto
	for y in size:
		for x in size:
			if (x < 8 and y < 8) or (x > size - 9 and y < 8) or (x < 8 and y > size - 9):
				continue
			if rng.randf() < 0.45:
				img.set_pixel(x, y, black)
	return ImageTexture.create_from_image(img)


func _reward_name_for_era() -> String:
	match GameState.selected_era_id:
		"era_8bit":
			var def: CartridgeRegistry.CartridgeDef = CartridgeRegistry.get_def("reset_button")
			return def.display_name if def != null else "Reset Button"
		"era_16bit":
			var def2: CartridgeRegistry.CartridgeDef = CartridgeRegistry.get_def("region_free")
			return def2.display_name if def2 != null else "Region Free"
	return "?"


func _make_button(text: String, victory: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	# Largura reduzida pra 2 botões caberem horizontalmente.
	btn.custom_minimum_size = Vector2(140, 28)
	btn.add_theme_font_size_override("font_size", 16)

	var accent: Color = Color("#306230") if victory else Color("#7a0030")
	var hilight: Color = Color("#9bbc0f") if victory else Color("#ff0080")

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.05, 1.0) if victory else Color(0.1, 0.0, 0.05, 1.0)
	sb.border_color = accent
	sb.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = accent
	sb_focus.border_color = hilight
	sb_focus.set_border_width_all(4)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn


func _on_retry() -> void:
	SceneRouter.go_to_arena()


func _on_menu() -> void:
	SceneRouter.go_to_main_menu()
