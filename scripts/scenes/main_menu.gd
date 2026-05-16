## Tela de menu principal — agora com intro animada estilo SNES:
##   - Estrelas parallax no fundo
##   - Logo do título cai do topo com bounce
##   - Subtítulo escreve com typewriter
##   - "PRESS START" piscando
##   - Mascote GAMO no canto
extends Control

const TITLE_COLOR := Color("#9bbc0f")
const SUB_COLOR := Color("#ffeb3b")

var _title_label: Label
var _press_start_label: Label
var _vbox: VBoxContainer
var _stars_layer: Node2D
var _tagline: TypewriterLabel
var _press_start_phase: float = 0.0
var _intro_complete: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(640, 360)
	_build()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_play_intro()


func _play_intro() -> void:
	# Botões começam escondidos, aparecem após a animação.
	_vbox.modulate.a = 0.0
	# Título cai do topo com bounce.
	_title_label.position.y = -120
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_title_label, "position:y", 40.0, 0.7) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BOUNCE)
	# Tagline typewriter logo após o título cair.
	var tag_timer := create_tween()
	tag_timer.tween_interval(0.55)
	tag_timer.tween_callback(func(): _tagline.type_text("by gamo.games", 0.06))
	# Botões fazem fade-in depois do título.
	var fade := create_tween()
	fade.tween_interval(0.9)
	fade.tween_property(_vbox, "modulate:a", 1.0, 0.4)
	fade.tween_callback(_on_intro_complete)


func _on_intro_complete() -> void:
	_intro_complete = true


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a14")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Estrelas parallax animadas (2 camadas em velocidades diferentes).
	_stars_layer = _MenuStars.new()
	add_child(_stars_layer)

	var scanlines := Sprite2D.new()
	scanlines.texture = _make_scanline_texture()
	scanlines.region_enabled = true
	scanlines.region_rect = Rect2(0, 0, 640, 360)
	scanlines.position = Vector2(320, 180)
	scanlines.modulate = Color(1, 1, 1, 0.18)
	add_child(scanlines)

	# Mascote GAMO no canto inferior-direito (sprite animado tier 1).
	var mascot := AnimatedSprite2D.new()
	mascot.sprite_frames = Sprites.make_animation(
		Sprites.GAMO_T1_IDLE, Sprites.PALETTE_GAMO, 2.4
	)
	mascot.play("default")
	mascot.centered = true
	mascot.scale = Vector2(3.0, 3.0)
	mascot.position = Vector2(540, 280)
	add_child(mascot)

	_title_label = Label.new()
	_title_label.text = I18n.t("menu_title")
	_title_label.add_theme_font_size_override("font_size", 44)
	_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	_title_label.add_theme_color_override("font_outline_color", Color("#306230"))
	_title_label.add_theme_constant_override("outline_size", 4)
	_title_label.anchor_left = 0.5
	_title_label.anchor_right = 0.5
	_title_label.anchor_top = 0.0
	_title_label.anchor_bottom = 0.0
	_title_label.position = Vector2(-160, 40)
	_title_label.size = Vector2(320, 120)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.pivot_offset = Vector2(160, 60)
	add_child(_title_label)

	var subtitle := Label.new()
	subtitle.text = I18n.t("menu_version")
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", SUB_COLOR)
	subtitle.anchor_left = 0.5
	subtitle.anchor_right = 0.5
	subtitle.position = Vector2(-80, 164)
	subtitle.size = Vector2(160, 20)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	# Tagline typewriter pra reforçar a marca Gamo.
	_tagline = TypewriterLabel.new()
	_tagline.add_theme_font_size_override("font_size", 11)
	_tagline.add_theme_color_override("font_color", Color("#00e5ff"))
	_tagline.add_theme_color_override("font_outline_color", Color.BLACK)
	_tagline.add_theme_constant_override("outline_size", 2)
	_tagline.anchor_left = 0.5
	_tagline.anchor_right = 0.5
	_tagline.position = Vector2(-140, 184)
	_tagline.size = Vector2(280, 16)
	_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_tagline)

	_vbox = VBoxContainer.new()
	_vbox.anchor_left = 0.5
	_vbox.anchor_right = 0.5
	_vbox.position = Vector2(-80, 192)
	_vbox.size = Vector2(160, 80)
	_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	_vbox.add_theme_constant_override("separation", 8)
	add_child(_vbox)

	var play_btn := _make_button(I18n.t("menu_play"))
	play_btn.pressed.connect(_on_play)
	_vbox.add_child(play_btn)

	var options_btn := _make_button(I18n.t("menu_options"))
	options_btn.pressed.connect(_on_options)
	_vbox.add_child(options_btn)

	var quit_btn := _make_button(I18n.t("menu_quit"))
	quit_btn.pressed.connect(_on_quit)
	_vbox.add_child(quit_btn)

	# "PRESS START" piscando logo abaixo dos botões
	_press_start_label = Label.new()
	_press_start_label.text = "►  PRESS START  ◄"
	_press_start_label.add_theme_font_size_override("font_size", 12)
	_press_start_label.add_theme_color_override("font_color", Color("#ffeb3b"))
	_press_start_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_press_start_label.add_theme_constant_override("outline_size", 2)
	_press_start_label.anchor_left = 0.5
	_press_start_label.anchor_right = 0.5
	_press_start_label.position = Vector2(-110, 300)
	_press_start_label.size = Vector2(220, 16)
	_press_start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_press_start_label)

	var stats := Label.new()
	stats.text = _format_stats()
	stats.add_theme_font_size_override("font_size", 12)
	stats.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	stats.anchor_top = 1.0
	stats.anchor_bottom = 1.0
	stats.position = Vector2(8, -32)
	stats.size = Vector2(400, 28)
	add_child(stats)

	var hint := Label.new()
	hint.text = I18n.t("menu_controls_hint")
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.anchor_right = 1.0
	hint.position = Vector2(-320, -16)
	hint.size = Vector2(312, 16)
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


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(160, 28)
	btn.add_theme_font_size_override("font_size", 18)

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


func _on_options() -> void:
	SceneRouter.go_to_options()


func _on_quit() -> void:
	SceneRouter.quit()
