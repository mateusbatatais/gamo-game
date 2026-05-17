## Toast que aparece quando uma nova lore card é desbloqueada.
## Similar ao AchievementToast mas com flavor de carta (estilo Pokémon TCG).
class_name LoreCardToast
extends CanvasLayer

const SHOW_DURATION := 4.0
const SLIDE_TIME := 0.4
const TOAST_WIDTH := 300.0
const TOAST_HEIGHT := 80.0


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.lore_card_unlocked.connect(_on_card_unlocked)


func _on_card_unlocked(card_id: String) -> void:
	var def: LoreCardRegistry.LoreCardDef = LoreCardRegistry.get_def(card_id)
	if def == null:
		return
	_spawn_toast(def)
	Audio.play(Audio.Sfx.UI_CONFIRM)


func _spawn_toast(def: LoreCardRegistry.LoreCardDef) -> void:
	var existing_count: int = get_child_count()
	var panel := Panel.new()
	panel.size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)
	panel.position = Vector2(640, 12 + existing_count * (TOAST_HEIGHT + 8))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.18, 0.95)
	sb.border_color = def.accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	# Header tag
	var tag := Label.new()
	tag.text = "NOVA CARTA — %s" % LoreCardRegistry.rarity_label(def.rarity)
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", LoreCardRegistry.rarity_color(def.rarity))
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 2)
	tag.position = Vector2(10, 6)
	tag.size = Vector2(TOAST_WIDTH - 20, 12)
	panel.add_child(tag)

	# Subtítulo
	var subtitle_lbl := Label.new()
	subtitle_lbl.text = def.subtitle
	subtitle_lbl.add_theme_font_size_override("font_size", 10)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	subtitle_lbl.position = Vector2(10, 20)
	subtitle_lbl.size = Vector2(TOAST_WIDTH - 20, 10)
	panel.add_child(subtitle_lbl)

	# Título grande com accent
	var title_lbl := Label.new()
	title_lbl.text = def.title
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", def.accent)
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	title_lbl.add_theme_constant_override("outline_size", 2)
	title_lbl.position = Vector2(10, 32)
	title_lbl.size = Vector2(TOAST_WIDTH - 20, 22)
	panel.add_child(title_lbl)

	# Preview do flavor (1 linha)
	var body_lbl := Label.new()
	body_lbl.text = def.body
	body_lbl.add_theme_font_size_override("font_size", 10)
	body_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	body_lbl.position = Vector2(10, 54)
	body_lbl.size = Vector2(TOAST_WIDTH - 20, 22)
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.clip_text = true
	panel.add_child(body_lbl)

	# Animação: slide in da direita, hold, slide out + free.
	var target_x: float = 640.0 - TOAST_WIDTH - 12.0
	var tween := panel.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ignore_time_scale(true)
	tween.tween_property(panel, "position:x", target_x, SLIDE_TIME)
	tween.tween_interval(SHOW_DURATION)
	tween.tween_property(panel, "position:x", 640.0, SLIDE_TIME)
	tween.tween_callback(panel.queue_free)
