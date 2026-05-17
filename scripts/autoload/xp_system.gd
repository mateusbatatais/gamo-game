## Sistema de XP e level-up. Mantém estado da run atual.
extends Node

# Curva mais lenta: precisa de mais gemas pra subir de nível e o crescimento
# por level é mais acentuado, deixando a run mais longa e o level-up mais especial.
const BASE_XP_NEEDED := 10
const XP_GROWTH := 1.5  # multiplicador por nível

var level: int = 1
var current_xp: int = 0
var xp_needed: int = BASE_XP_NEEDED
var _pending_levelups: int = 0


func _ready() -> void:
	EventBus.run_started.connect(_reset)


func _reset() -> void:
	level = 1
	current_xp = 0
	xp_needed = BASE_XP_NEEDED
	_pending_levelups = 0


func add_xp(amount: int) -> void:
	# Multiplicador de upgrade permanente "xp_gain" aplicado aqui.
	amount = int(round(float(amount) * UpgradeRegistry.get_xp_multiplier()))
	# Modificador da run (ex: GREED -30%).
	amount = int(round(float(amount) * ModifierSystem.xp_mult()))
	current_xp += amount
	var leveled := false
	# Slow-mo curto se vai rolar um level-up — dá o momento de "uau".
	if current_xp >= xp_needed:
		HitStop.slow_mo_levelup()
	while current_xp >= xp_needed:
		# Trava a barra visível em 100% antes do level-up para o jogador ver o estouro.
		# Sem isso o modal abre com a barra já reiniciada e parece que avançou cedo.
		EventBus.xp_gained.emit(0, xp_needed, xp_needed)
		current_xp -= xp_needed
		level += 1
		_pending_levelups += 1
		xp_needed = int(BASE_XP_NEEDED * pow(XP_GROWTH, level - 1))
		EventBus.player_leveled_up.emit(level)
		Audio.play(Audio.Sfx.LEVEL_UP)
		leveled = true
	if not leveled:
		EventBus.xp_gained.emit(amount, current_xp, xp_needed)


## Reemite o estado atual da barra. Chamar quando o modal de level-up fecha,
## para mostrar o XP residual após o consumo do nível.
func refresh_bar() -> void:
	EventBus.xp_gained.emit(0, current_xp, xp_needed)


func has_pending_levelup() -> bool:
	return _pending_levelups > 0


func consume_levelup() -> void:
	_pending_levelups = max(0, _pending_levelups - 1)
