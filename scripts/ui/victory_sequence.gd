## Sequência cinemática de vitória final — exibida quando o player derrota
## o boss da última fase. Ondas de partículas amarelas/verdes, GAMO destacado,
## texto épico bouncing, vinheta dourada.
## Após ~3s emite 'finished' pra arena finalizar pro game-over.
class_name VictorySequence
extends Node2D

signal finished

const DURATION := 3.0
const SHAKE_AMP := 6.0

var _layer: CanvasLayer
var _vignette: ColorRect
var _title: Label
var _subtitle: Label
var _gamo_sprite: AnimatedSprite2D
var _age: float = 0.0
var _ended: bool = false
var _burst_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Inicia a sequência. center_pos é onde o boss estava (epicentro das partículas).
func start(center_pos: Vector2) -> void:
	global_position = center_pos
	_build_overlay()
	HitStop.freeze(0.18)
	_trigger_shake()
	# Spawn 10 ondas de partículas (douradas/verdes/brancas)
	for wave in 12:
		var delay: float = float(wave) * 0.13
		var t := get_tree().create_timer(delay, true, false, true)
		t.timeout.connect(_spawn_victory_burst)
	# Para a música — silêncio dramático antes do game-over.
	Music.stop()
	# Final
	get_tree().create_timer(DURATION, true, false, true).timeout.connect(_finalize)


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 9
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	# Vinheta dourada
	_vignette = ColorRect.new()
	_vignette.color = Color("#1a2a08")
	_vignette.modulate.a = 0.0
	_vignette.anchor_right = 1.0
	_vignette.anchor_bottom = 1.0
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_vignette)
	var v_tween := _vignette.create_tween()
	v_tween.set_ignore_time_scale(true)
	v_tween.tween_property(_vignette, "modulate:a", 0.45, 1.2).set_ease(Tween.EASE_IN)

	# Título gigante "VITORIA" entrando com bounce
	_title = Label.new()
	_title.text = "VITORIA"
	_title.add_theme_font_size_override("font_size", 72)
	_title.add_theme_color_override("font_color", Color("#ffeb3b"))
	_title.add_theme_color_override("font_outline_color", Color("#7a5a08"))
	_title.add_theme_constant_override("outline_size", 8)
	_title.anchor_left = 0.5
	_title.anchor_right = 0.5
	_title.anchor_top = 0.5
	_title.position = Vector2(-260, -80)
	_title.size = Vector2(520, 80)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.pivot_offset = Vector2(260, 40)
	_title.scale = Vector2(0.1, 0.1)
	_title.modulate = Color(1, 1, 1, 0)
	_layer.add_child(_title)
	var t_tween := _title.create_tween().set_parallel(true)
	t_tween.set_ignore_time_scale(true)
	t_tween.tween_property(_title, "scale", Vector2.ONE, 0.55) \
		.set_delay(0.25) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	t_tween.tween_property(_title, "modulate:a", 1.0, 0.4).set_delay(0.25)

	# Subtítulo "COLECAO RESTAURADA" digitando
	var typewriter := TypewriterLabel.new()
	typewriter.add_theme_font_size_override("font_size", 18)
	typewriter.add_theme_color_override("font_color", Color("#9bbc0f"))
	typewriter.add_theme_color_override("font_outline_color", Color.BLACK)
	typewriter.add_theme_constant_override("outline_size", 3)
	typewriter.anchor_left = 0.5
	typewriter.anchor_right = 0.5
	typewriter.anchor_top = 0.5
	typewriter.position = Vector2(-240, 10)
	typewriter.size = Vector2(480, 24)
	typewriter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layer.add_child(typewriter)
	_subtitle = typewriter
	# Espera o título estabilizar antes de começar a digitar.
	var sub_timer := get_tree().create_timer(1.0, true, false, true)
	sub_timer.timeout.connect(_start_typing_subtitle)

	# Mascote GAMO em pose de vitória no canto direito
	_gamo_sprite = AnimatedSprite2D.new()
	_gamo_sprite.sprite_frames = Sprites.make_animation(
		Sprites.GAMO_T3_IDLE, SkinRegistry.active_palette(), 3.0
	)
	_gamo_sprite.play("default")
	_gamo_sprite.centered = true
	_gamo_sprite.scale = Vector2(3.0, 3.0)
	_gamo_sprite.position = Vector2(540, 280)
	_gamo_sprite.modulate.a = 0.0
	_layer.add_child(_gamo_sprite)
	var g_tween := _gamo_sprite.create_tween()
	g_tween.set_ignore_time_scale(true)
	g_tween.tween_property(_gamo_sprite, "modulate:a", 1.0, 0.6).set_delay(1.4)


func _start_typing_subtitle() -> void:
	if _subtitle != null:
		var tw := _subtitle as TypewriterLabel
		tw.type_text("COLECAO ETERNA RESTAURADA", 0.05)


func _spawn_victory_burst() -> void:
	if not is_instance_valid(get_parent()):
		return
	var dp := DeathParticle.new()
	dp.global_position = global_position + Vector2(
		randf_range(-60.0, 60.0), randf_range(-60.0, 60.0)
	)
	# Cores comemorativas — amarelo/verde/branco com flash dourado.
	var col: Color
	var roll: float = randf()
	if roll < 0.4:
		col = Color("#ffeb3b")  # amarelo
	elif roll < 0.7:
		col = Color("#9bbc0f")  # verde Game Boy
	elif roll < 0.9:
		col = Color("#ffffff")  # branco
	else:
		col = Color("#ffc107")  # dourado
	dp.setup(col)
	get_parent().add_child(dp)
	_burst_count += 1
	# Shake reduz com o tempo
	if _burst_count % 3 == 0:
		_trigger_shake()


func _trigger_shake() -> void:
	var n: Node = get_parent()
	while n != null and not n.has_method("trigger_shake"):
		n = n.get_parent()
	if n != null:
		n.call("trigger_shake", SHAKE_AMP, 0.4)


func _finalize() -> void:
	if _ended:
		return
	_ended = true
	finished.emit()
