## Time effects: hit-stop (freeze) e slow-mo (time_scale < 1).
##   - freeze() / freeze_big() — freeze total por 80-180ms (crits, morte miniboss)
##   - slow_mo(scale, duration) — abranda o tempo (ex: 0.3× por 0.4s em level-ups)
## Implementado via Engine.time_scale + timer ALWAYS pra restaurar.
extends Node

const DEFAULT_DURATION := 0.08  # 80ms — punchy mas não interrompe gameplay
const BIG_DURATION := 0.18      # eventos maiores (morte de miniboss)
const SLOW_MO_LEVELUP_SCALE := 0.3
const SLOW_MO_LEVELUP_DURATION := 0.35
const SLOW_MO_BOSS_SCALE := 0.2
const SLOW_MO_BOSS_DURATION := 0.9

var _restore_time: float = 0.0
var _previous_time_scale: float = 1.0
var _active: bool = false
var _active_scale: float = 0.0


func _ready() -> void:
	# Roda mesmo com tree pausado/tempo zerado.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Dispara um hit-stop curto (default 80ms). Chamadas sucessivas estendem
## a duração se a nova ultrapassar a anterior, mas não acumulam.
func freeze(duration: float = DEFAULT_DURATION) -> void:
	_apply(0.0, duration)


func freeze_big() -> void:
	freeze(BIG_DURATION)


## Slow-motion — abranda o tempo pra X (0 < X < 1) por Y segundos.
## Sobrescreve um freeze ativo só se for "menos restritivo" (scale maior).
func slow_mo(scale: float, duration: float) -> void:
	_apply(clampf(scale, 0.05, 0.95), duration)


## Atalhos pra os casos mais comuns
func slow_mo_levelup() -> void:
	slow_mo(SLOW_MO_LEVELUP_SCALE, SLOW_MO_LEVELUP_DURATION)


func slow_mo_boss_death() -> void:
	slow_mo(SLOW_MO_BOSS_SCALE, SLOW_MO_BOSS_DURATION)


func _apply(scale: float, duration: float) -> void:
	if not _active:
		_previous_time_scale = Engine.time_scale
	_active = true
	# Se já tem um efeito ativo, mantém o MAIS LENTO (menor scale).
	if scale < _active_scale or not _active:
		_active_scale = scale
	Engine.time_scale = _active_scale
	var until: float = _now() + duration
	if until > _restore_time:
		_restore_time = until


func _process(_delta: float) -> void:
	if not _active:
		return
	if _now() >= _restore_time:
		Engine.time_scale = _previous_time_scale
		_active = false
		_active_scale = 0.0


func _now() -> float:
	return float(Time.get_ticks_msec()) * 0.001
