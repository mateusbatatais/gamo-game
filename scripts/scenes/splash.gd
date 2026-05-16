## Splash de boot do jogo: "powered by gamo.games" com fade-in/out de 2.4s.
## Vai direto pro main_menu (ou pra intro cinemática se for a primeira run).
extends Control

const TOTAL_DURATION := 2.4
const FADE_IN := 0.5
const HOLD := 1.2

var _logo: Control
var _tag: Label
var _age: float = 0.0
var _next_scene_triggered: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(640, 360)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#000000")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Container central
	_logo = Control.new()
	_logo.anchor_left = 0.5
	_logo.anchor_right = 0.5
	_logo.anchor_top = 0.5
	_logo.anchor_bottom = 0.5
	_logo.position = Vector2(-160, -32)
	_logo.size = Vector2(320, 64)
	_logo.modulate.a = 0.0
	add_child(_logo)

	# "POWERED BY" pequeno em cima
	var label_top := Label.new()
	label_top.text = "POWERED BY"
	label_top.add_theme_font_size_override("font_size", 12)
	label_top.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	label_top.add_theme_color_override("font_outline_color", Color.BLACK)
	label_top.add_theme_constant_override("outline_size", 2)
	label_top.size = Vector2(320, 14)
	label_top.position = Vector2(0, 4)
	label_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.add_child(label_top)

	# "gamo.games" grande em ciano
	var label_main := Label.new()
	label_main.text = "gamo.games"
	label_main.add_theme_font_size_override("font_size", 36)
	label_main.add_theme_color_override("font_color", Color("#00e5ff"))
	label_main.add_theme_color_override("font_outline_color", Color.BLACK)
	label_main.add_theme_constant_override("outline_size", 4)
	label_main.size = Vector2(320, 44)
	label_main.position = Vector2(0, 18)
	label_main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.add_child(label_main)


func _process(delta: float) -> void:
	_age += delta
	# Fade in até FADE_IN, sustenta até FADE_IN+HOLD, fade out até TOTAL_DURATION.
	if _age <= FADE_IN:
		_logo.modulate.a = _age / FADE_IN
	elif _age <= FADE_IN + HOLD:
		_logo.modulate.a = 1.0
	else:
		var fade_t: float = (_age - FADE_IN - HOLD) / (TOTAL_DURATION - FADE_IN - HOLD)
		_logo.modulate.a = 1.0 - clampf(fade_t, 0.0, 1.0)

	if _age >= TOTAL_DURATION and not _next_scene_triggered:
		_next_scene_triggered = true
		_go_next()


func _go_next() -> void:
	# Sempre toca a intro — ela é skippable com qualquer tecla.
	SceneRouter.go_to_intro()


func _input(event: InputEvent) -> void:
	# Skip rápido com qualquer tecla/clique.
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed() and not _next_scene_triggered:
			_next_scene_triggered = true
			_go_next()
