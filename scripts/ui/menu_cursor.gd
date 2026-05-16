## Seta pixelada que segue o Control focado nos menus.
## Auto-gerencia layer pra renderizar por cima dos botões.
class_name MenuCursor
extends CanvasLayer

const SPRITE_SCALE := 2.0
const ARROW_BOB_AMPLITUDE := 3.0
const ARROW_BOB_SPEED := 6.0

# Seta apontando pra DIREITA (▶) — fica à esquerda do botão focado.
const ARROW: Array = [
	[
		"#.....",
		"##....",
		"###...",
		"####..",
		"#####.",
		"######",
		"#####.",
		"####..",
		"###...",
		"##....",
		"#.....",
	],
]

const PALETTE := {
	"#": Color("#ffeb3b"),
	"=": Color("#ff9800"),
}

var _sprite: Sprite2D
var _target: Control = null
var _bob_phase: float = 0.0


func _ready() -> void:
	layer = 7  # acima do HUD, abaixo de modais
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.make_sprite(PackedStringArray(ARROW[0]), PALETTE)
	_sprite.centered = true
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.modulate = Color.WHITE
	add_child(_sprite)
	visible = false
	# Escuta mudanças globais de foco.
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func _on_focus_changed(ctrl: Control) -> void:
	_target = ctrl
	visible = ctrl != null


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		visible = false
		return
	_bob_phase += delta * ARROW_BOB_SPEED
	var bob: float = sin(_bob_phase) * ARROW_BOB_AMPLITUDE
	var target_rect: Rect2 = _target.get_global_rect()
	# Posiciona à esquerda do botão, centralizado verticalmente.
	_sprite.position = Vector2(
		target_rect.position.x - 14 - bob,
		target_rect.position.y + target_rect.size.y * 0.5,
	)
	# Pulso de scale leve pra dar vida
	var pulse: float = 1.0 + 0.08 * sin(_bob_phase * 2.0)
	_sprite.scale = Vector2(SPRITE_SCALE * pulse, SPRITE_SCALE * pulse)
