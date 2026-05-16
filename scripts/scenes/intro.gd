## Intro cinemática contando a origem do GAMO e a ameaça do Glitch.
## Sequência de slides com fundo + sprite procedural + texto typewriter.
## Skippable com qualquer tecla. Marca intro_seen ao terminar.
extends Control

const NEXT_DELAY_AFTER_TYPE := 1.8  # tempo antes do próximo slide após terminar typewriter
const FADE_TIME := 0.4

class Slide:
	var bg_color: Color
	var sprite_kind: String  ## "cartridges", "glitch", "gamo", "boss", "fight", "none"
	var sprite_color: Color
	var text: String
	var char_interval: float = 0.03

	func _init(p_bg: Color, p_sprite: String, p_color: Color, p_text: String, p_interval: float = 0.03) -> void:
		bg_color = p_bg
		sprite_kind = p_sprite
		sprite_color = p_color
		text = p_text
		char_interval = p_interval


var _slides: Array[Slide] = []
var _slide_index: int = 0
var _bg: ColorRect
var _sprite_node: Node2D
var _text_label: TypewriterLabel
var _hint_label: Label
var _hint_phase: float = 0.0
var _transitioning: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(640, 360)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_define_slides()
	_build()
	_show_slide(0)


func _define_slides() -> void:
	_slides = [
		Slide.new(
			Color("#0a0a14"), "cartridges", Color("#9bbc0f"),
			"No coração da plataforma gamo.games existe a Coleção Eterna — todo cartucho que já existiu, em harmonia digital."
		),
		Slide.new(
			Color("#0a0014"), "glitch", Color("#e040fb"),
			"Um vírus desconhecido apareceu: O GLITCH. Sua corrupção começou a apagar cartuchos de eras inteiras."
		),
		Slide.new(
			Color("#001a14"), "gamo", Color("#00e5ff"),
			"Para defender o arquivo, a plataforma despertou seu mascote: GAMO, um spirit binário com forma de robô."
		),
		Slide.new(
			Color("#1a0010"), "boss", Color("#ff5252"),
			"Mas o Glitch não veio sozinho. Bosses guardam cada era corrompida, mutações de bugs lendários."
		),
		Slide.new(
			Color("#0a1a0a"), "fight", Color("#ffeb3b"),
			"Sua missão: invadir cada era, derrotar a corrupção, recuperar os cartuchos. Catalogar é resistir."
		),
		Slide.new(
			Color("#000000"), "none", Color("#00e5ff"),
			"A Coleção Eterna conta com você. Hora de ligar o sistema.",
			0.04
		),
	]


func _build() -> void:
	_bg = ColorRect.new()
	_bg.color = Color.BLACK
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	add_child(_bg)

	_sprite_node = Node2D.new()
	_sprite_node.position = Vector2(320, 130)
	add_child(_sprite_node)

	# Painel de texto no rodapé
	var text_panel := Panel.new()
	text_panel.anchor_left = 0.5
	text_panel.anchor_right = 0.5
	text_panel.position = Vector2(-300, 230)
	text_panel.size = Vector2(600, 88)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.08, 0.85)
	sb.border_color = Color("#00e5ff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	text_panel.add_theme_stylebox_override("panel", sb)
	add_child(text_panel)

	_text_label = TypewriterLabel.new()
	_text_label.add_theme_font_size_override("font_size", 14)
	_text_label.add_theme_color_override("font_color", Color.WHITE)
	_text_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_text_label.add_theme_constant_override("outline_size", 2)
	_text_label.position = Vector2(12, 10)
	_text_label.size = Vector2(576, 68)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_panel.add_child(_text_label)

	# Hint embaixo
	_hint_label = Label.new()
	_hint_label.text = "PRESS START / SPACE / ESC pra pular"
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.78))
	_hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint_label.add_theme_constant_override("outline_size", 2)
	_hint_label.anchor_left = 1.0
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_right = 1.0
	_hint_label.anchor_bottom = 1.0
	_hint_label.position = Vector2(-220, -22)
	_hint_label.size = Vector2(212, 16)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_hint_label)


func _process(delta: float) -> void:
	_hint_phase += delta * 3.0
	_hint_label.modulate.a = 0.5 + 0.5 * (0.5 + 0.5 * sin(_hint_phase))


func _show_slide(index: int) -> void:
	if index >= _slides.size():
		_finish()
		return
	_slide_index = index
	var slide: Slide = _slides[index]
	_bg.color = slide.bg_color
	_render_sprite(slide.sprite_kind, slide.sprite_color)
	_text_label.type_text(slide.text, slide.char_interval)
	# Aguarda terminar e avança automaticamente.
	if _text_label.finished.is_connected(_on_typewriter_done):
		_text_label.finished.disconnect(_on_typewriter_done)
	_text_label.finished.connect(_on_typewriter_done, CONNECT_ONE_SHOT)


func _on_typewriter_done() -> void:
	if _transitioning:
		return
	# Pausa pequena depois do texto terminar, depois avança.
	var timer := get_tree().create_timer(NEXT_DELAY_AFTER_TYPE, true)
	timer.timeout.connect(_advance)


func _advance() -> void:
	if _transitioning:
		return
	_show_slide(_slide_index + 1)


func _finish() -> void:
	if _transitioning:
		return
	_transitioning = true
	GameState.mark_intro_seen()
	SceneRouter.go_to_main_menu()


func _input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).keycode
		match k:
			KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER:
				_finish()
				get_viewport().set_input_as_handled()
				return
			KEY_SPACE:
				# Avança slide manualmente
				if _text_label.text != _slides[_slide_index].text:
					_text_label.finish_now()
				else:
					_advance()
				get_viewport().set_input_as_handled()


func _render_sprite(kind: String, color: Color) -> void:
	for child in _sprite_node.get_children():
		child.queue_free()
	match kind:
		"cartridges":
			_draw_cartridges_scene(color)
		"glitch":
			_draw_glitch_scene(color)
		"gamo":
			_draw_gamo_scene(color)
		"boss":
			_draw_boss_scene(color)
		"fight":
			_draw_fight_scene(color)
		"none":
			pass


func _draw_cartridges_scene(color: Color) -> void:
	# 5 cartuchos enfileirados representando a coleção
	for i in 5:
		var cart := ColorRect.new()
		cart.color = color
		cart.size = Vector2(40, 56)
		cart.position = Vector2(-110 + i * 44, -28)
		_sprite_node.add_child(cart)
		# Etiqueta no topo
		var tag := ColorRect.new()
		tag.color = Color(1, 1, 1, 0.7)
		tag.size = Vector2(28, 8)
		tag.position = Vector2(-104 + i * 44, -22)
		_sprite_node.add_child(tag)


func _draw_glitch_scene(color: Color) -> void:
	# Grade de quadradinhos magenta + alguns "rasgos" horizontais
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in 90:
		var sq := ColorRect.new()
		sq.color = color if rng.randf() < 0.6 else Color.BLACK
		sq.color.a = rng.randf_range(0.4, 1.0)
		var size: float = rng.randf_range(4, 12)
		sq.size = Vector2(size, size)
		sq.position = Vector2(rng.randf_range(-150, 150), rng.randf_range(-50, 50))
		_sprite_node.add_child(sq)


func _draw_gamo_scene(color: Color) -> void:
	# Sprite grande do GAMO tier 3 centralizado
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.GAMO_T3_IDLE, Sprites.PALETTE_GAMO, 2.4
	)
	sprite.play("default")
	sprite.centered = true
	sprite.scale = Vector2(4.0, 4.0)
	_sprite_node.add_child(sprite)
	# Aura ciano em volta
	for r in 3:
		var ring := ColorRect.new()
		var s: float = 96.0 + r * 24.0
		ring.size = Vector2(s, s)
		ring.position = Vector2(-s * 0.5, -s * 0.5)
		ring.color = Color(color.r, color.g, color.b, 0.08 - r * 0.02)
		_sprite_node.add_child(ring)
		_sprite_node.move_child(ring, 0)


func _draw_boss_scene(color: Color) -> void:
	# 3 silhuetas de bosses imponentes
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 3:
		var x: float = -100.0 + i * 100.0
		# Corpo grande
		var body := ColorRect.new()
		body.color = color
		body.size = Vector2(56, 56)
		body.position = Vector2(x - 28, -28)
		_sprite_node.add_child(body)
		# Olhos
		for ey in 2:
			var eye := ColorRect.new()
			eye.color = Color.WHITE
			eye.size = Vector2(6, 6)
			eye.position = Vector2(x - 14 + ey * 16, -14)
			_sprite_node.add_child(eye)


func _draw_fight_scene(color: Color) -> void:
	# GAMO no centro com projéteis saindo em raios
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.GAMO_T2_IDLE, Sprites.PALETTE_GAMO, 2.4
	)
	sprite.play("default")
	sprite.centered = true
	sprite.scale = Vector2(3.0, 3.0)
	_sprite_node.add_child(sprite)
	# Raios amarelos pra fora
	for i in 8:
		var ang: float = TAU * float(i) / 8.0
		var ray := ColorRect.new()
		ray.color = color
		ray.size = Vector2(30, 4)
		ray.position = Vector2(
			cos(ang) * 60.0 - 15.0,
			sin(ang) * 60.0 - 2.0
		)
		ray.rotation = ang
		_sprite_node.add_child(ray)
