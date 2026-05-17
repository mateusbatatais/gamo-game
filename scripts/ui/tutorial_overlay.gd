## Tutorial overlay — aparece só na primeira run. Mostra cards de instrução
## em momentos específicos (start, primeiro kill, primeiro level-up, primeiro boss).
## Auto-disabilita após GameState.mark_tutorial_seen().
class_name TutorialOverlay
extends CanvasLayer

const HINT_DURATION := 5.0
const HINT_FADE := 0.4

var _completed_hints: Dictionary = {}
var _enabled: bool = false


func _ready() -> void:
	layer = 9  # acima do HUD (5), abaixo de modals (10+)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_enabled = not GameState.tutorial_seen
	if not _enabled:
		return
	EventBus.run_started.connect(_on_run_started)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.boss_warning.connect(_on_boss_warning)


func _on_run_started() -> void:
	if not _enabled:
		return
	_show_hint("controls", "MOVA com WASD/setas. DASH com espaço.\nTiros são automáticos — só sobreviva.")


func _on_enemy_killed(_enemy: Node2D, _xp: int) -> void:
	if not _enabled or "kill" in _completed_hints:
		return
	_show_hint("kill", "Inimigos largam gemas de XP.\nColete pra subir de nível.")


func _on_level_up(_lvl: int) -> void:
	if not _enabled or "levelup" in _completed_hints:
		return
	_show_hint("levelup", "Escolha 1 cartucho de 3 sorteados.\nMaxe e combine pra evoluções lendárias.")


func _on_boss_warning() -> void:
	if not _enabled:
		return
	_show_hint("boss", "BOSS chegando!\nFica longe dos ataques e ataque em rajadas seguras.")
	# Boss warning marca fim do tutorial — depois disso o jogador já viu o essencial.
	GameState.mark_tutorial_seen()
	_enabled = false


func _show_hint(id: String, text: String) -> void:
	if id in _completed_hints:
		return
	_completed_hints[id] = true

	var panel := Panel.new()
	panel.size = Vector2(360, 56)
	panel.position = Vector2(140, 280)
	panel.modulate.a = 0.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.03, 0.08, 0.95)
	sb.border_color = Color("#ffeb3b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var tag := Label.new()
	tag.text = "[TUTORIAL]"
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color("#ffeb3b"))
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 2)
	tag.position = Vector2(8, 4)
	tag.size = Vector2(344, 12)
	panel.add_child(tag)

	var body := Label.new()
	body.text = text
	body.add_theme_font_size_override("font_size", 11)
	body.add_theme_color_override("font_color", Color.WHITE)
	body.add_theme_color_override("font_outline_color", Color.BLACK)
	body.add_theme_constant_override("outline_size", 2)
	body.position = Vector2(8, 16)
	body.size = Vector2(344, 36)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(body)

	# Fade-in, hold, fade-out
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, HINT_FADE)
	tween.tween_interval(HINT_DURATION)
	tween.tween_property(panel, "modulate:a", 0.0, HINT_FADE)
	tween.tween_callback(panel.queue_free)
