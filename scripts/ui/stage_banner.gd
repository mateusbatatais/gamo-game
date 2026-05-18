## Banner dramático que aparece ao avançar de fase. Mostra nome da nova era
## em fonte grande + subtítulo de "DIFICULDADE +X%". Slide-in do topo, hold
## ~2s, slide-out. CanvasLayer próprio (layer 9) — acima do HUD, abaixo de modais.
class_name StageBanner
extends CanvasLayer

const SLIDE_TIME := 0.35
const HOLD_TIME := 1.8
const SLIDE_OUT_TIME := 0.4

var _panel: Panel
var _title: Label
var _subtitle: Label


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	_panel = Panel.new()
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.position = Vector2(0, -60)  # começa acima da tela
	_panel.size = Vector2(640, 60)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.08, 0.92)
	sb.border_color = Color("#00e5ff")
	sb.set_border_width_all(2)
	sb.border_width_top = 0
	sb.border_width_left = 0
	sb.border_width_right = 0
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", Color("#ffeb3b"))
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 4)
	_title.anchor_right = 1.0
	_title.position = Vector2(0, 6)
	_title.size = Vector2(640, 28)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_title)

	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", 12)
	_subtitle.add_theme_color_override("font_color", Color("#ff5252"))
	_subtitle.add_theme_color_override("font_outline_color", Color.BLACK)
	_subtitle.add_theme_constant_override("outline_size", 2)
	_subtitle.anchor_right = 1.0
	_subtitle.position = Vector2(0, 36)
	_subtitle.size = Vector2(640, 16)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_subtitle)


## Dispara o banner com nome da fase e percentual de dificuldade aumentado.
## difficulty_pct: número inteiro (e.g., 60 → "DIFICULDADE +60%").
func show_stage(stage_number: int, era_name: String, difficulty_pct: int) -> void:
	_title.text = "FASE %d — %s" % [stage_number, era_name.to_upper()]
	if difficulty_pct > 0:
		_subtitle.text = "▲ DIFICULDADE +%d%%  ▲" % difficulty_pct
	else:
		_subtitle.text = ""
	_panel.position.y = -60
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "position:y", 0.0, SLIDE_TIME)
	tween.tween_interval(HOLD_TIME)
	tween.tween_property(_panel, "position:y", -60.0, SLIDE_OUT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
