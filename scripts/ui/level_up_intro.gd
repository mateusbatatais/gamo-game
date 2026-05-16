## Sequência cinematográfica antes do modal de level-up:
##   1. Todos os inimigos da tela explodem em cascata (particles)
##   2. Texto "LEVEL UP!" surge com bounce e wobble
##   3. Sinaliza 'finished' quando termina pra arena abrir o modal de cartuchos
##
## Roda com process_mode = ALWAYS porque a árvore fica pausada durante a intro.
class_name LevelUpIntro
extends Node2D

signal finished

const DURATION := 1.35
const TEXT_GROW_TIME := 0.35
const EXPLOSION_STAGGER := 0.04
const EXPLOSION_COLORS := [
	Color("#ffeb3b"),  # amarelo
	Color("#ff9800"),  # laranja
	Color("#ff5252"),  # vermelho
	Color("#e040fb"),  # magenta
]

var _age: float = 0.0
var _label: Label
var _ended: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_label()


func _build_label() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9  # acima do HUD (5) e abaixo do modal (10)
	add_child(layer)

	_label = Label.new()
	_label.text = "LEVEL UP!"
	_label.add_theme_font_size_override("font_size", 56)
	_label.add_theme_color_override("font_color", Color("#ffeb3b"))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.anchor_left = 0.5
	_label.anchor_right = 0.5
	_label.anchor_top = 0.5
	_label.anchor_bottom = 0.5
	_label.position = Vector2(-180, -32)
	_label.size = Vector2(360, 64)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.pivot_offset = Vector2(180, 32)
	_label.scale = Vector2(0.1, 0.1)
	_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	layer.add_child(_label)


## Recebe as posições world-space dos inimigos a explodir.
## Particles vão sendo spawnadas escalonadamente em cascata.
func start(positions: Array) -> void:
	var i: int = 0
	for pos in positions:
		var delay: float = float(i) * EXPLOSION_STAGGER
		# create_timer(time, process_always=true) pra rodar mesmo com tree pausada.
		var t := get_tree().create_timer(delay, true)
		t.timeout.connect(_spawn_explosion.bind(pos, i))
		i += 1


func _spawn_explosion(pos: Vector2, seq: int) -> void:
	var particle := DeathParticle.new()
	particle.process_mode = Node.PROCESS_MODE_ALWAYS
	particle.global_position = pos
	particle.setup(EXPLOSION_COLORS[seq % EXPLOSION_COLORS.size()])
	add_child(particle)


func _process(delta: float) -> void:
	if _ended:
		return
	_age += delta
	# Animação do label: cresce do nada com easing back-out, depois wobble suave.
	var alpha: float = clampf(_age / 0.18, 0.0, 1.0)
	var t: float = clampf(_age / TEXT_GROW_TIME, 0.0, 1.0)
	var s: float = lerpf(0.1, 1.3, _ease_back_out(t))
	if _age > TEXT_GROW_TIME:
		# Wobble suave que decai
		var settle_t: float = (_age - TEXT_GROW_TIME) / (DURATION - TEXT_GROW_TIME)
		var wobble_amp: float = lerpf(0.12, 0.0, settle_t)
		s = 1.0 + sin((_age - TEXT_GROW_TIME) * 16.0) * wobble_amp
	# Fade out no final
	if _age > DURATION - 0.25:
		alpha = clampf((DURATION - _age) / 0.25, 0.0, 1.0)
	_label.scale = Vector2(s, s)
	_label.modulate.a = alpha

	if _age >= DURATION:
		_ended = true
		finished.emit()


## Easing back-out (overshoots e settles) — dá impacto ao "LEVEL UP".
func _ease_back_out(x: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)
