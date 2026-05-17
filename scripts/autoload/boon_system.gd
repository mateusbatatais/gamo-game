## Gerencia boons temporários ativos no player. Cada boon tem duração e um
## efeito aplicado ao player; ao expirar, reverte. UI mostra os ativos via signal.
extends Node

enum Kind {
	DOUBLE_SHOT,
	CRIT_SURGE,
	SPEED_BOOST,
	MAGNET_FIELD,
	IRON_SKIN,
}

class ActiveBoon:
	var kind: int
	var time_left: float
	var duration_total: float

	func _init(p_kind: int, p_duration: float) -> void:
		kind = p_kind
		time_left = p_duration
		duration_total = p_duration


const DURATIONS: Dictionary = {
	Kind.DOUBLE_SHOT: 20.0,
	Kind.CRIT_SURGE: 22.0,
	Kind.SPEED_BOOST: 18.0,
	Kind.MAGNET_FIELD: 25.0,
	Kind.IRON_SKIN: 16.0,
}

const NAMES: Dictionary = {
	Kind.DOUBLE_SHOT: "DOUBLE SHOT",
	Kind.CRIT_SURGE: "CRIT SURGE",
	Kind.SPEED_BOOST: "SPEED BOOST",
	Kind.MAGNET_FIELD: "MAGNET FIELD",
	Kind.IRON_SKIN: "IRON SKIN",
}

const COLORS: Dictionary = {
	Kind.DOUBLE_SHOT: Color("#ffeb3b"),
	Kind.CRIT_SURGE: Color("#ff5252"),
	Kind.SPEED_BOOST: Color("#00e5ff"),
	Kind.MAGNET_FIELD: Color("#e040fb"),
	Kind.IRON_SKIN: Color("#9bbc0f"),
}

# Multiplicadores aplicados no player enquanto o boon estiver ativo.
const SPEED_MULT := 1.30
const MAGNET_MULT := 2.0
const CRIT_BONUS := 0.25
const DMG_REDUCTION := 0.5  # iron_skin: dano recebido × 0.5

# Stats originais do player (snapshot pra reverter).
var _player: Player = null
var _orig_move_speed: float = 0.0
var _orig_pickup_mult: float = 0.0
var _orig_crit_chance: float = 0.0
var _active: Array[ActiveBoon] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	EventBus.run_started.connect(_on_run_started)


func _on_run_started() -> void:
	_active.clear()
	_player = null
	EventBus.boons_changed.emit(active_kinds())


## Chamado pelo Arena após spawnar o player.
func bind_player(player: Player) -> void:
	_player = player
	_orig_move_speed = player.move_speed
	_orig_pickup_mult = player.pickup_radius_mult
	_orig_crit_chance = player.crit_chance


## Pickup de boon ativa um efeito por X segundos.
func grant(kind: int) -> void:
	if _player == null:
		return
	# Se já existe esse boon ativo, reseta a duração.
	for boon in _active:
		if boon.kind == kind:
			boon.time_left = DURATIONS[kind]
			EventBus.boons_changed.emit(active_kinds())
			return
	var b := ActiveBoon.new(kind, DURATIONS[kind])
	_active.append(b)
	_apply(kind, true)
	EventBus.boons_changed.emit(active_kinds())


## Dano que o player recebe deve passar por aqui se IRON_SKIN tá ativo.
## Retorna o dano final ajustado.
func filter_damage(amount: int) -> int:
	if _player == null:
		return amount
	if has_active(Kind.IRON_SKIN):
		return int(round(float(amount) * DMG_REDUCTION))
	return amount


func has_active(kind: int) -> bool:
	for b in _active:
		if b.kind == kind:
			return true
	return false


func active_kinds() -> Array:
	var arr: Array = []
	for b in _active:
		arr.append(b)
	return arr


func _apply(kind: int, on: bool) -> void:
	if _player == null:
		return
	var sign_mult: float = 1.0 if on else -1.0
	match kind:
		Kind.SPEED_BOOST:
			# Recalcula sempre baseado no original — evita drift se aplicar/reverter várias vezes.
			if on:
				_player.move_speed = _orig_move_speed * SPEED_MULT
			else:
				_player.move_speed = _orig_move_speed
		Kind.MAGNET_FIELD:
			if on:
				_player.pickup_radius_mult = _orig_pickup_mult * MAGNET_MULT
			else:
				_player.pickup_radius_mult = _orig_pickup_mult
		Kind.CRIT_SURGE:
			if on:
				_player.crit_chance = clampf(_orig_crit_chance + CRIT_BONUS, 0.0, 1.0)
			else:
				_player.crit_chance = _orig_crit_chance
		Kind.DOUBLE_SHOT:
			# DOUBLE_SHOT é consultado pelos cartuchos via has_active no momento do disparo.
			pass
		Kind.IRON_SKIN:
			# IRON_SKIN consultado por filter_damage.
			pass


func _process(delta: float) -> void:
	if _active.is_empty() or _player == null:
		return
	if not GameState.run_active:
		return
	var expired: Array[ActiveBoon] = []
	for b in _active:
		b.time_left -= delta
		if b.time_left <= 0.0:
			expired.append(b)
	for b in expired:
		_apply(b.kind, false)
		_active.erase(b)
	if not expired.is_empty():
		EventBus.boons_changed.emit(active_kinds())
