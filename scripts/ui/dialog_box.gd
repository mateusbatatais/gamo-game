## Caixa de diálogo contextual (estilo "log de sistema" do GAMO).
## Aparece no topo da tela, texto typewriter, fade-out automático após hold.
class_name DialogBox
extends CanvasLayer

const HOLD_TIME := 2.6
const FADE_TIME := 0.35
const BOX_WIDTH := 480.0
const BOX_HEIGHT := 56.0

var _panel: Panel
var _speaker_label: Label
var _text_label: TypewriterLabel


func _ready() -> void:
	layer = 6  # acima do HUD (5), abaixo do modal de level-up (10)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build()


func _build() -> void:
	_panel = Panel.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.position = Vector2(-BOX_WIDTH * 0.5, 40)
	_panel.size = Vector2(BOX_WIDTH, BOX_HEIGHT)
	_panel.modulate.a = 0.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.08, 0.92)
	sb.border_color = Color("#00e5ff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	# Header pequeno tipo "log entry"
	_speaker_label = Label.new()
	_speaker_label.text = "[GAMO.SYS]"
	_speaker_label.add_theme_font_size_override("font_size", 10)
	_speaker_label.add_theme_color_override("font_color", Color("#00e5ff"))
	_speaker_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_speaker_label.add_theme_constant_override("outline_size", 2)
	_speaker_label.position = Vector2(10, 4)
	_speaker_label.size = Vector2(BOX_WIDTH - 20, 14)
	add_child_to_panel(_speaker_label)

	# Texto principal (typewriter)
	_text_label = TypewriterLabel.new()
	_text_label.add_theme_font_size_override("font_size", 14)
	_text_label.add_theme_color_override("font_color", Color.WHITE)
	_text_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_text_label.add_theme_constant_override("outline_size", 2)
	_text_label.position = Vector2(10, 20)
	_text_label.size = Vector2(BOX_WIDTH - 20, 32)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child_to_panel(_text_label)


func add_child_to_panel(node: Node) -> void:
	_panel.add_child(node)


## Exibe um diálogo: header (speaker) + texto typewriter, hold, fade-out.
func show_message(speaker: String, message: String, accent: Color = Color("#00e5ff")) -> void:
	_speaker_label.text = "[%s]" % speaker
	_speaker_label.add_theme_color_override("font_color", accent)
	# Atualiza borda da caixa pra cor do speaker.
	var sb := _panel.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		sb.border_color = accent
	_text_label.type_text(message, 0.025)
	# Fade-in rápido, hold, fade-out.
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
	tween.tween_interval(HOLD_TIME)
	tween.tween_property(_panel, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)
