## Dispara one-liners contextuais do GAMO durante a run.
## Escuta eventos do EventBus + GameState e seleciona frase aleatória do banco.
## Mantém cooldown global pra não floodar a tela com mensagens.
extends Node

const COOLDOWN := 4.5  # segundos mínimos entre dialogs
const LOW_HP_THRESHOLD := 0.30

# Banco de frases por categoria. Cada call escolhe uma aleatória.
const LINES_LOW_HP := [
	"Energia crítica! Atenção!",
	"Sistema instável... HP no vermelho.",
	"Cuidado, GAMO. Quase apagando.",
]
const LINES_COMBO_25 := [
	"Sequência impecável!",
	"25 sem erro. Continua!",
	"Streak ativa. Catalogando.",
]
const LINES_COMBO_50 := [
	"Box Completo. Você tá em chamas.",
	"50 hits sem falhar — exibido.",
]
const LINES_COMBO_100 := [
	"MINT CONDITION. Inacreditável.",
	"100 sem amassar. Tô orgulhoso.",
]
const LINES_LEVEL_UP_HIGH := [
	"Nível 10 atingido. Armadura pesada online.",
	"Forma final desbloqueada!",
]
const LINES_HEALTH_PICKUP := [
	"Energia recuperada. Obrigado.",
	"Pacote de saúde sincronizado.",
]
const LINES_ACHIEVEMENT := [
	"Conquista catalogada. Adicionada ao arquivo.",
	"Marco registrado!",
]

var _cooldown: float = 0.0
var _low_hp_triggered: bool = false
var _combo_announced: int = 0  # último combo já anunciado (25/50/100)
var _last_dialog_parent: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
	EventBus.run_started.connect(_on_run_started)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func _on_run_started() -> void:
	# Reseta estado por run.
	_cooldown = 0.0
	_low_hp_triggered = false
	_combo_announced = 0


func _on_player_damaged(_amount: int, current: int, maximum: int) -> void:
	if maximum <= 0:
		return
	var ratio: float = float(current) / float(maximum)
	if ratio <= LOW_HP_THRESHOLD and not _low_hp_triggered and current > 0:
		_low_hp_triggered = true
		_say_random(LINES_LOW_HP, Color("#ff5252"))


func _on_player_healed(_a: int, current: int, maximum: int) -> void:
	# Se voltou pra acima do threshold, libera novo aviso.
	if maximum <= 0:
		return
	var ratio: float = float(current) / float(maximum)
	if ratio > LOW_HP_THRESHOLD + 0.15:
		_low_hp_triggered = false
		# Comemora pickup ocasionalmente (50% de chance)
		if current < maximum and randf() < 0.5:
			_say_random(LINES_HEALTH_PICKUP, Color("#69f0ae"))


func _on_combo_changed(combo: int) -> void:
	# Anuncia marcos de combo só na primeira vez que atinge.
	if combo >= 100 and _combo_announced < 100:
		_combo_announced = 100
		_say_random(LINES_COMBO_100, Color("#ffeb3b"))
	elif combo >= 50 and _combo_announced < 50:
		_combo_announced = 50
		_say_random(LINES_COMBO_50, Color("#ff9800"))
	elif combo >= 25 and _combo_announced < 25:
		_combo_announced = 25
		_say_random(LINES_COMBO_25, Color("#00e5ff"))
	# Reset do tracker se quebrou combo
	if combo == 0:
		_combo_announced = 0


func _on_level_up(new_level: int) -> void:
	if new_level == 10:
		_say_random(LINES_LEVEL_UP_HIGH, Color("#00e5ff"))


func _on_achievement_unlocked(_id: String) -> void:
	# Frequência baixa pra não competir com o toast de achievement.
	if randf() < 0.4:
		_say_random(LINES_ACHIEVEMENT, Color("#ffeb3b"))


func _say_random(lines: Array, accent: Color) -> void:
	if _cooldown > 0.0:
		return
	if lines.is_empty():
		return
	var line: String = lines[randi() % lines.size()]
	_say(line, accent)


func _say(message: String, accent: Color) -> void:
	# Encontra a cena atual e spawna o DialogBox nela.
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	var dlg := DialogBox.new()
	parent.add_child(dlg)
	dlg.show_message("GAMO.SYS", message, accent)
	_cooldown = COOLDOWN
	_last_dialog_parent = parent
