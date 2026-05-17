## Listener global do código Konami (↑ ↑ ↓ ↓ ← → ← → B A).
## Quando completado, desbloqueia a skin "Cheat Code" + lore card secreta.
## Roda em qualquer cena via _unhandled_input.
extends Node

const SEQUENCE: Array[int] = [
	KEY_UP, KEY_UP,
	KEY_DOWN, KEY_DOWN,
	KEY_LEFT, KEY_RIGHT,
	KEY_LEFT, KEY_RIGHT,
	KEY_B, KEY_A,
]
# Mapeamento alternativo via WASD pra quem joga com mão na esquerda.
const SEQUENCE_WASD: Array[int] = [
	KEY_W, KEY_W,
	KEY_S, KEY_S,
	KEY_A, KEY_D,
	KEY_A, KEY_D,
	KEY_B, KEY_A,
]
const TIMEOUT := 4.5  ## reseta se demorar mais que isso entre teclas

var _progress_arrow: int = 0
var _progress_wasd: int = 0
var _last_key_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	# Usa _input (não _unhandled_input) porque buttons focados consomem setas
	# pra navegação, e o código depende de detectar as setas globalmente.
	# Não marcamos o evento como handled — UI continua funcionando normalmente.
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	# Timeout — reseta progresso se demorou demais.
	if _last_key_time > 0.0 and now - _last_key_time > TIMEOUT:
		_progress_arrow = 0
		_progress_wasd = 0
	_last_key_time = now
	var keycode: int = key_event.keycode
	_advance(keycode, SEQUENCE, "_progress_arrow")
	_advance(keycode, SEQUENCE_WASD, "_progress_wasd")


func _advance(keycode: int, sequence: Array[int], prop: String) -> void:
	if GameState.konami_unlocked:
		return
	var idx: int = int(get(prop))
	if keycode == sequence[idx]:
		idx += 1
		if idx >= sequence.size():
			_trigger()
			idx = 0
	else:
		# Se a tecla é o primeiro elemento da sequência, recomeça em 1 (não 0).
		idx = 1 if keycode == sequence[0] else 0
	set(prop, idx)


func _trigger() -> void:
	if GameState.konami_unlocked:
		return
	GameState.unlock_konami()
	GameState.unlock_skin("konami")
	# Feedback dramatico: dialog box + audio.
	Audio.play(Audio.Sfx.UI_CONFIRM)
	var parent: Node = get_tree().current_scene
	if parent != null:
		var dlg := DialogBox.new()
		parent.add_child(dlg)
		dlg.show_message(
			"GAMO.SYS",
			"+30 VIDAS. Skin Cheat Code desbloqueada na estante.",
			Color("#ffeb3b")
		)
