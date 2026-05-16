## Toast que aparece no canto superior direito quando uma conquista é desbloqueada.
## Escorrega da direita pra dentro, segura 3.5s, sai. Empilha múltiplas.
class_name AchievementToast
extends CanvasLayer

const SHOW_DURATION := 3.5
const SLIDE_TIME := 0.35
const TOAST_WIDTH := 280.0
const TOAST_HEIGHT := 56.0


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(id: String) -> void:
	var def: AchievementRegistry.AchievementDef = AchievementRegistry.get_def(id)
	if def == null:
		return
	_spawn_toast(def.display_name, def.description)
	Audio.play(Audio.Sfx.LEVEL_UP)


func _spawn_toast(title: String, desc: String) -> void:
	var existing_count: int = get_child_count()
	var panel := Panel.new()
	panel.size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)
	panel.position = Vector2(640, 12 + existing_count * (TOAST_HEIGHT + 6))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.18, 0.95)
	sb.border_color = Color("#ffeb3b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var tag := Label.new()
	tag.text = "CONQUISTA!"
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color("#ffeb3b"))
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 2)
	tag.position = Vector2(8, 4)
	tag.size = Vector2(TOAST_WIDTH - 16, 14)
	panel.add_child(tag)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	title_lbl.add_theme_constant_override("outline_size", 2)
	title_lbl.position = Vector2(8, 18)
	title_lbl.size = Vector2(TOAST_WIDTH - 16, 18)
	panel.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	desc_lbl.position = Vector2(8, 38)
	desc_lbl.size = Vector2(TOAST_WIDTH - 16, 14)
	desc_lbl.clip_text = true
	panel.add_child(desc_lbl)

	# Slide in, hold, slide out + free.
	var target_x: float = 640.0 - TOAST_WIDTH - 12.0
	var tween := panel.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "position:x", target_x, SLIDE_TIME)
	tween.tween_interval(SHOW_DURATION)
	tween.tween_property(panel, "position:x", 640.0, SLIDE_TIME)
	tween.tween_callback(panel.queue_free)
