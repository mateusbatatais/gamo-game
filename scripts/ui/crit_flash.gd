## Flash de tela leve quando crítico acontece. CanvasLayer global que renderiza
## um ColorRect amarelo pálido fullscreen com alpha curta. Empilhamento de
## múltiplos crits seguidos vai sumindo (não satura).
##
## Registrado como autoload "CritFlash" — chame CritFlash.flash() de qualquer
## lugar. Sem class_name pra evitar conflito com o autoload singleton.
extends CanvasLayer

const FLASH_DURATION := 0.10
const FLASH_PEAK_ALPHA := 0.18

var _rect: ColorRect
var _age: float = -1.0  ## negativo = inativo


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(1.0, 0.95, 0.4, 0.0)
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


## Dispara o flash. Pode ser chamado por qualquer crit em qualquer entidade.
func flash() -> void:
	_age = 0.0


func _process(delta: float) -> void:
	if _age < 0.0:
		return
	_age += delta
	if _age >= FLASH_DURATION:
		_age = -1.0
		_rect.color.a = 0.0
		return
	# Triangular envelope: cresce rápido até pico, depois cai.
	var t: float = _age / FLASH_DURATION
	var env: float = 1.0 - abs(t * 2.0 - 1.0)  # 0 → 1 → 0
	_rect.color.a = env * FLASH_PEAK_ALPHA
