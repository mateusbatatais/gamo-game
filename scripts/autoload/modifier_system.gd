## Modificadores de Run — curses + blessings escolhidos antes da run.
## Cada modificador tem um bônus e um custo, criando tradeoffs interessantes.
## A cada partida, o jogador pode escolher 1 dos 3 modificadores sorteados,
## ou pular pra jogar sem modificador.
##
## Sistema query-based: player/enemy/registries chamam ModifierSystem para saber
## os multiplicadores ativos. Reset ao terminar a run.
extends Node

class ModifierDef:
	var id: String
	var display_name: String
	var blessing: String  ## texto positivo (ganho)
	var curse: String     ## texto negativo (custo)
	var accent: Color

	# Multiplicadores que o modifier aplica. Defaults = 1.0 / 0 / false (sem efeito).
	var damage_mult: float = 1.0
	var hp_mult: float = 1.0
	var move_speed_mult: float = 1.0
	var enemy_speed_mult: float = 1.0
	var tokens_mult: float = 1.0
	var xp_mult: float = 1.0
	var damage_taken_mult: float = 1.0
	var freeze_duration_mult: float = 1.0
	## crit_chance_override: -1.0 = sem override, >= 0 = força esse valor
	var crit_chance_override: float = -1.0
	var crit_mult_override: float = -1.0

	func _init(
		p_id: String, p_name: String, p_bless: String, p_curse: String, p_accent: Color
	) -> void:
		id = p_id
		display_name = p_name
		blessing = p_bless
		curse = p_curse
		accent = p_accent


var _registry: Dictionary = {}
var _order: Array[String] = []
var active_id: String = ""  ## "" = sem modificador


func _ready() -> void:
	_register_all()
	EventBus.run_ended.connect(_on_run_ended)


func _register_all() -> void:
	var m1 := ModifierDef.new(
		"glass_cannon", "GLASS CANNON",
		"+50% dano",
		"-50% HP máximo",
		Color("#ff5252")
	)
	m1.damage_mult = 1.5
	m1.hp_mult = 0.5
	_add(m1)

	var m2 := ModifierDef.new(
		"speed_demon", "SPEED DEMON",
		"+40% velocidade",
		"Inimigos +25% velocidade",
		Color("#00e5ff")
	)
	m2.move_speed_mult = 1.4
	m2.enemy_speed_mult = 1.25
	_add(m2)

	var m3 := ModifierDef.new(
		"greed", "GREED",
		"+75% tokens",
		"-30% XP",
		Color("#ffeb3b")
	)
	m3.tokens_mult = 1.75
	m3.xp_mult = 0.7
	_add(m3)

	var m4 := ModifierDef.new(
		"masochist", "MASOCHIST",
		"Tokens x3",
		"Dano recebido x2",
		Color("#e040fb")
	)
	m4.tokens_mult = 3.0
	m4.damage_taken_mult = 2.0
	_add(m4)

	var m5 := ModifierDef.new(
		"perma_crit", "PERMA-CRIT",
		"Todo hit é crítico",
		"Crit mult reduzido a 1.5x",
		Color("#ff9800")
	)
	m5.crit_chance_override = 1.0
	m5.crit_mult_override = 1.5
	_add(m5)

	var m6 := ModifierDef.new(
		"frostbite", "FROSTBITE",
		"Freezes duram 3x mais",
		"-25% dano",
		Color("#90caf9")
	)
	m6.freeze_duration_mult = 3.0
	m6.damage_mult = 0.75
	_add(m6)

	var m7 := ModifierDef.new(
		"bullet_hell", "BULLET HELL",
		"+30% dano, +30% velocidade",
		"Inimigos +40% velocidade",
		Color("#9bbc0f")
	)
	m7.damage_mult = 1.3
	m7.move_speed_mult = 1.3
	m7.enemy_speed_mult = 1.4
	_add(m7)


func _add(def: ModifierDef) -> void:
	_registry[def.id] = def
	_order.append(def.id)


func get_def(id: String) -> ModifierDef:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	return _order.duplicate()


## Sorteia N ids aleatórios e distintos pra o draft.
func draft(count: int = 3) -> Array[String]:
	var pool: Array[String] = _order.duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))


func set_active(id: String) -> void:
	if id != "" and not _registry.has(id):
		return
	active_id = id


func clear() -> void:
	active_id = ""


func is_active() -> bool:
	return active_id != ""


func active_def() -> ModifierDef:
	return get_def(active_id)


# --- Query helpers (chamadas pelos sistemas) ---

func damage_mult() -> float:
	var d: ModifierDef = active_def()
	return d.damage_mult if d != null else 1.0


func hp_mult() -> float:
	var d: ModifierDef = active_def()
	return d.hp_mult if d != null else 1.0


func move_speed_mult() -> float:
	var d: ModifierDef = active_def()
	return d.move_speed_mult if d != null else 1.0


func enemy_speed_mult() -> float:
	var d: ModifierDef = active_def()
	return d.enemy_speed_mult if d != null else 1.0


func tokens_mult() -> float:
	var d: ModifierDef = active_def()
	return d.tokens_mult if d != null else 1.0


func xp_mult() -> float:
	var d: ModifierDef = active_def()
	return d.xp_mult if d != null else 1.0


func damage_taken_mult() -> float:
	var d: ModifierDef = active_def()
	return d.damage_taken_mult if d != null else 1.0


func freeze_duration_mult() -> float:
	var d: ModifierDef = active_def()
	return d.freeze_duration_mult if d != null else 1.0


## Retorna -1.0 quando não há override (usar valor padrão do player).
func crit_chance_override() -> float:
	var d: ModifierDef = active_def()
	return d.crit_chance_override if d != null else -1.0


func crit_mult_override() -> float:
	var d: ModifierDef = active_def()
	return d.crit_mult_override if d != null else -1.0


func _on_run_ended(_v: bool, _stats: Dictionary) -> void:
	clear()
