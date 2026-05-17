## Tela de menu principal — layout limpo SNES:
##   - Título com frame chunky, duas linhas em duas cores (verde+amarelo)
##   - Tagline "by gamo.games" abaixo do título com typewriter
##   - Mascote GAMO grande e centralizado (hero pose)
##   - 3 botões em linha horizontal abaixo do mascote
##   - "PRESS START" piscando + stats no rodapé
extends Control

const TITLE_GREEN := Color("#9bbc0f")
const TITLE_YELLOW := Color("#ffeb3b")
const TITLE_GREEN_OUTLINE := Color("#306230")
const TITLE_YELLOW_OUTLINE := Color("#5a3f10")

var _title_panel: Panel
var _line1: Label
var _line2: Label
var _press_start_label: Label
var _hbox: HBoxContainer
var _stars_layer: Node2D
var _tagline: TypewriterLabel
var _mascot: AnimatedSprite2D
var _press_start_phase: float = 0.0
var _intro_complete: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(640, 360)
	_build()
	process_mode = Node.PROCESS_MODE_ALWAYS
	Music.play_menu()
	_play_intro()


func _play_intro() -> void:
	# Elementos começam escondidos, aparecem após a animação.
	_hbox.modulate.a = 0.0
	_mascot.modulate.a = 0.0
	# Título desce do topo com bounce.
	_title_panel.position.y = -130
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_title_panel, "position:y", 8.0, 0.7) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BOUNCE)
	# Tagline typewriter após o título.
	var tag_timer := create_tween()
	tag_timer.tween_interval(0.55)
	tag_timer.tween_callback(func(): _tagline.type_text("by gamo.games", 0.06))
	# Mascote fade-in junto com a tagline.
	var mascot_fade := create_tween()
	mascot_fade.tween_interval(0.6)
	mascot_fade.tween_property(_mascot, "modulate:a", 1.0, 0.5)
	# Botões aparecem por último.
	var fade := create_tween()
	fade.tween_interval(1.0)
	fade.tween_property(_hbox, "modulate:a", 1.0, 0.4)
	fade.tween_callback(_on_intro_complete)


func _on_intro_complete() -> void:
	_intro_complete = true


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#050510")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Estrelas parallax animadas no fundo.
	_stars_layer = _MenuStars.new()
	add_child(_stars_layer)

	# Scanlines globais leves
	var scanlines := Sprite2D.new()
	scanlines.texture = _make_scanline_texture()
	scanlines.region_enabled = true
	scanlines.region_rect = Rect2(0, 0, 640, 360)
	scanlines.position = Vector2(320, 180)
	scanlines.modulate = Color(1, 1, 1, 0.18)
	add_child(scanlines)

	# --- Título com frame chunky e duas cores ---
	_title_panel = Panel.new()
	_title_panel.anchor_left = 0.5
	_title_panel.anchor_right = 0.5
	_title_panel.position = Vector2(-220, 8)
	_title_panel.size = Vector2(440, 96)
	_title_panel.pivot_offset = Vector2(220, 48)
	var title_sb := PanelFrames.chunky(
		Color(0.0, 0.05, 0.02, 0.85),
		TITLE_GREEN,
		TITLE_GREEN_OUTLINE
	)
	_title_panel.add_theme_stylebox_override("panel", title_sb)
	add_child(_title_panel)

	_line1 = Label.new()
	_line1.text = "CARTRIDGE"
	_line1.add_theme_font_size_override("font_size", 36)
	_line1.add_theme_color_override("font_color", TITLE_GREEN)
	_line1.add_theme_color_override("font_outline_color", TITLE_GREEN_OUTLINE)
	_line1.add_theme_constant_override("outline_size", 4)
	_line1.position = Vector2(0, 4)
	_line1.size = Vector2(440, 42)
	_line1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_panel.add_child(_line1)

	_line2 = Label.new()
	_line2.text = "CRUSADE"
	_line2.add_theme_font_size_override("font_size", 36)
	_line2.add_theme_color_override("font_color", TITLE_YELLOW)
	_line2.add_theme_color_override("font_outline_color", TITLE_YELLOW_OUTLINE)
	_line2.add_theme_constant_override("outline_size", 4)
	_line2.position = Vector2(0, 48)
	_line2.size = Vector2(440, 42)
	_line2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_panel.add_child(_line2)

	# Tagline typewriter logo abaixo do título (sem overlap com botões).
	_tagline = TypewriterLabel.new()
	_tagline.add_theme_font_size_override("font_size", 12)
	_tagline.add_theme_color_override("font_color", Color("#00e5ff"))
	_tagline.add_theme_color_override("font_outline_color", Color.BLACK)
	_tagline.add_theme_constant_override("outline_size", 2)
	_tagline.anchor_left = 0.5
	_tagline.anchor_right = 0.5
	_tagline.position = Vector2(-140, 112)
	_tagline.size = Vector2(280, 16)
	_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_tagline)

	# --- Mascote GAMO grande e centralizado (hero pose, sem aura quadrada) ---
	_mascot = AnimatedSprite2D.new()
	_mascot.sprite_frames = Sprites.make_animation(
		Sprites.GAMO_T1_IDLE, Sprites.PALETTE_GAMO, 2.4
	)
	_mascot.play("default")
	_mascot.centered = true
	_mascot.scale = Vector2(4.0, 4.0)
	_mascot.position = Vector2(320, 200)
	add_child(_mascot)

	# --- Botões em linha horizontal abaixo do mascote ---
	# 5 botões agora (RUN DIÁRIA + DIÁRIO + OPÇÕES + JOGAR + SAIR). 84x32 cada.
	# 5*84 + 4*8 = 452. Aumenta um pouco a largura do hbox.
	_hbox = HBoxContainer.new()
	_hbox.anchor_left = 0.5
	_hbox.anchor_right = 0.5
	_hbox.position = Vector2(-228, 260)
	_hbox.size = Vector2(456, 32)
	_hbox.add_theme_constant_override("separation", 8)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_hbox)

	var play_btn := _make_button(I18n.t("menu_play"), 84)
	play_btn.pressed.connect(_on_play)
	_hbox.add_child(play_btn)

	var daily_btn := _make_button("DIÁRIA", 84)
	daily_btn.pressed.connect(_on_open_daily)
	_hbox.add_child(daily_btn)

	var diary_btn := _make_button("DIÁRIO", 84)
	diary_btn.pressed.connect(_on_open_diary)
	_hbox.add_child(diary_btn)

	var options_btn := _make_button(I18n.t("menu_options"), 84)
	options_btn.pressed.connect(_on_options)
	_hbox.add_child(options_btn)

	var quit_btn := _make_button(I18n.t("menu_quit"), 84)
	quit_btn.pressed.connect(_on_quit)
	_hbox.add_child(quit_btn)

	# Painéis modais (escondidos até abrir).
	var diary := RunDiary.new()
	diary.name = "RunDiary"
	add_child(diary)

	var daily_panel := DailyRunPanel.new()
	daily_panel.name = "DailyRunPanel"
	add_child(daily_panel)

	# "PRESS START" piscando no rodapé
	_press_start_label = Label.new()
	_press_start_label.text = "►  PRESS START  ◄"
	_press_start_label.add_theme_font_size_override("font_size", 12)
	_press_start_label.add_theme_color_override("font_color", Color("#ffeb3b"))
	_press_start_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_press_start_label.add_theme_constant_override("outline_size", 2)
	_press_start_label.anchor_left = 0.5
	_press_start_label.anchor_right = 0.5
	_press_start_label.position = Vector2(-110, 304)
	_press_start_label.size = Vector2(220, 16)
	_press_start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_press_start_label)

	# Stats discreto no rodapé esquerdo
	var stats := Label.new()
	stats.text = _format_stats()
	stats.add_theme_font_size_override("font_size", 10)
	stats.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	stats.anchor_top = 1.0
	stats.anchor_bottom = 1.0
	stats.position = Vector2(8, -16)
	stats.size = Vector2(440, 12)
	add_child(stats)

	# Hint de controles no rodapé direito
	var hint := Label.new()
	hint.text = I18n.t("menu_controls_hint")
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.anchor_right = 1.0
	hint.position = Vector2(-260, -16)
	hint.size = Vector2(252, 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)

	# Cursor SNES animado seguindo o foco.
	add_child(MenuCursor.new())
	play_btn.grab_focus()


func _process(delta: float) -> void:
	# "PRESS START" pulsa amarelo→laranja.
	if _press_start_label != null:
		_press_start_phase += delta * 3.0
		var t: float = 0.5 + 0.5 * sin(_press_start_phase)
		_press_start_label.modulate.a = lerpf(0.35, 1.0, t)


## Camada interna de estrelas parallax pra fundo do menu.
class _MenuStars extends Node2D:
	const COUNT_FAR := 40
	const COUNT_NEAR := 18

	var _far: Array[Vector2] = []
	var _near: Array[Vector2] = []
	var _far_phases: Array[float] = []

	func _ready() -> void:
		z_index = -50
		for i in COUNT_FAR:
			_far.append(Vector2(randf() * 640.0, randf() * 360.0))
			_far_phases.append(randf() * TAU)
		for i in COUNT_NEAR:
			_near.append(Vector2(randf() * 640.0, randf() * 360.0))
		set_process(true)

	func _process(delta: float) -> void:
		for i in _far.size():
			_far[i].x = fmod(_far[i].x + delta * 4.0, 640.0)
		for i in _near.size():
			_near[i].x = fmod(_near[i].x + delta * 12.0, 640.0)
		queue_redraw()

	func _draw() -> void:
		var t: float = float(Time.get_ticks_msec()) * 0.001
		for i in _far.size():
			var pulse: float = 0.4 + 0.4 * sin(t * 2.0 + _far_phases[i])
			draw_rect(Rect2(_far[i], Vector2(1, 1)), Color(1, 1, 1, pulse * 0.5), true)
		for pos in _near:
			draw_rect(Rect2(pos, Vector2(2, 2)), Color(0.9, 0.95, 1, 0.85), true)


func _make_button(text: String, width: int = 130) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, 32)
	btn.add_theme_font_size_override("font_size", 16)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.12, 0.18, 1.0)
	sb.border_color = Color("#306230")
	sb.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color("#306230")
	sb_focus.border_color = Color("#9bbc0f")
	sb_focus.set_border_width_all(4)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color("#9bbc0f"))
	btn.add_theme_color_override("font_focus_color", Color("#9bbc0f"))
	return btn


func _format_stats() -> String:
	var best_s := int(GameState.best_run_time)
	var best_str := "%d:%02d" % [best_s / 60, best_s % 60]
	return "Melhor tempo: %s   Kills totais: %d   Runs: %d" % [
		best_str, GameState.total_kills, GameState.total_runs
	]


func _make_scanline_texture() -> ImageTexture:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(0, 0, 0, 0))
	img.set_pixel(1, 0, Color(0, 0, 0, 0))
	img.set_pixel(0, 1, Color(0, 0, 0, 1))
	img.set_pixel(1, 1, Color(0, 0, 0, 1))
	return ImageTexture.create_from_image(img)


func _on_play() -> void:
	SceneRouter.go_to_hub()


func _on_open_diary() -> void:
	var panel := get_node_or_null("RunDiary") as RunDiary
	if panel != null:
		panel.open()


func _on_open_daily() -> void:
	var panel := get_node_or_null("DailyRunPanel") as DailyRunPanel
	if panel != null:
		panel.open()


func _on_options() -> void:
	SceneRouter.go_to_options()


func _on_quit() -> void:
	SceneRouter.quit()
