## Talent Tree — meta-progressão permanente paga com tokens.
## 6 nós, cada um com 3 níveis. Aplicam buffs passivos no player no início da run.
##
## Diferente dos Upgrades (efeitos fixos), os talents são mais "build-defining":
## chance de drop, range de XP, hp de start, etc.
extends Node

class TalentDef:
	var id: String
	var display_name: String
	var description: String  ## texto base do efeito (com %s pra valor por nível)
	var accent: Color
	var max_level: int = 3
	var cost_per_level: Array[int] = [10, 25, 60]  ## tokens pra cada nível

	func _init(
		p_id: String, p_name: String, p_desc: String, p_accent: Color, p_costs: Array[int]
	) -> void:
		id = p_id
		display_name = p_name
		description = p_desc
		accent = p_accent
		cost_per_level = p_costs


var _registry: Dictionary = {}
var _order: Array[String] = []


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	_add(TalentDef.new(
		"vital_chip", "VITAL CHIP",
		"+%d HP máximo de start",
		Color("#9bbc0f"),
		[10, 25, 60]
	))
	_add(TalentDef.new(
		"power_chip", "POWER CHIP",
		"+%d%% dano inicial",
		Color("#ff5252"),
		[15, 35, 80]
	))
	_add(TalentDef.new(
		"swift_chip", "SWIFT CHIP",
		"+%d%% velocidade de movimento",
		Color("#00e5ff"),
		[12, 30, 70]
	))
	_add(TalentDef.new(
		"magnet_chip", "MAGNET CHIP",
		"+%d%% range de coleta de XP",
		Color("#ffeb3b"),
		[10, 25, 60]
	))
	_add(TalentDef.new(
		"lucky_chip", "LUCKY CHIP",
		"+%d%% chance de drop de power-up",
		Color("#e040fb"),
		[15, 35, 80]
	))
	_add(TalentDef.new(
		"crit_chip", "CRIT CHIP",
		"+%d%% chance de crítico",
		Color("#ff9800"),
		[20, 50, 120]
	))


func _add(def: TalentDef) -> void:
	_registry[def.id] = def
	_order.append(def.id)


func get_def(id: String) -> TalentDef:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	return _order.duplicate()


func get_level(id: String) -> int:
	return int(GameState.talent_levels.get(id, 0))


## Custo pra subir 1 nível. Retorna -1 se já está no max.
func next_cost(id: String) -> int:
	var def: TalentDef = get_def(id)
	if def == null:
		return -1
	var lvl: int = get_level(id)
	if lvl >= def.max_level:
		return -1
	return def.cost_per_level[lvl]


## Tenta comprar 1 nível. Retorna true se conseguiu.
func purchase(id: String) -> bool:
	var cost: int = next_cost(id)
	if cost < 0:
		return false
	if not GameState.spend_tokens(cost):
		return false
	GameState.talent_levels[id] = get_level(id) + 1
	GameState.save_progress()
	return true


# --- Aplicação de buffs no player (chamado por player._ready) ---

## HP bônus flat (somado ao max_hp do spirit). 15/30/45 por nível.
func bonus_max_hp() -> int:
	return get_level("vital_chip") * 15


## Multiplicador de dano (1.0 + bonus). 10/22/40% por nível agregado.
func damage_mult_bonus() -> float:
	var lvl: int = get_level("power_chip")
	if lvl <= 0:
		return 0.0
	# +10% nv1, +22% nv2, +40% nv3 (escala mais que linear)
	return [0.10, 0.22, 0.40][lvl - 1]


## Multiplicador de velocidade (1.0 + bonus). +8/+18/+30%.
func move_speed_mult_bonus() -> float:
	var lvl: int = get_level("swift_chip")
	if lvl <= 0:
		return 0.0
	return [0.08, 0.18, 0.30][lvl - 1]


## Range de coleta (1.0 + bonus). +20/+45/+80%.
func pickup_range_mult_bonus() -> float:
	var lvl: int = get_level("magnet_chip")
	if lvl <= 0:
		return 0.0
	return [0.20, 0.45, 0.80][lvl - 1]


## Modificador absoluto na power_up_drop_chance dos inimigos. +0.3/+0.7/+1.5%.
func power_up_drop_bonus() -> float:
	var lvl: int = get_level("lucky_chip")
	if lvl <= 0:
		return 0.0
	return [0.003, 0.007, 0.015][lvl - 1]


## Bonus absoluto na crit_chance. +5/+12/+20 percentage points.
func crit_chance_bonus() -> float:
	var lvl: int = get_level("crit_chip")
	if lvl <= 0:
		return 0.0
	return [0.05, 0.12, 0.20][lvl - 1]


## Descrição renderizada com valor do nível atual (ou próximo se ainda não comprou).
func description_for(id: String) -> String:
	var def: TalentDef = get_def(id)
	if def == null:
		return ""
	var lvl: int = get_level(id)
	# Para mostrar o efeito no nível ATUAL: mapeia cada talent
	# pra valor cumulativo legível.
	var value_now: float = _talent_value(id, lvl)
	# Valor no próximo nível (se não maxou)
	var preview: String = ""
	if lvl < def.max_level:
		var next_value: float = _talent_value(id, lvl + 1)
		preview = "  →  %s" % _format_value(id, next_value)
	return "%s%s  (nv %d/%d)" % [
		_format_desc(id, value_now), preview, lvl, def.max_level
	]


func _talent_value(id: String, level: int) -> float:
	if level <= 0:
		return 0.0
	match id:
		"vital_chip":
			return float(level * 15)
		"power_chip":
			return [10.0, 22.0, 40.0][level - 1]
		"swift_chip":
			return [8.0, 18.0, 30.0][level - 1]
		"magnet_chip":
			return [20.0, 45.0, 80.0][level - 1]
		"lucky_chip":
			return [0.3, 0.7, 1.5][level - 1]
		"crit_chip":
			return [5.0, 12.0, 20.0][level - 1]
	return 0.0


func _format_value(id: String, value: float) -> String:
	match id:
		"vital_chip":
			return "+%d HP" % int(value)
		"lucky_chip":
			return "+%.1f%%" % value
		_:
			return "+%d%%" % int(value)


func _format_desc(id: String, value: float) -> String:
	match id:
		"vital_chip":
			return "+%d HP máximo" % int(value)
		"power_chip":
			return "+%d%% dano" % int(value)
		"swift_chip":
			return "+%d%% velocidade" % int(value)
		"magnet_chip":
			return "+%d%% range XP" % int(value)
		"lucky_chip":
			return "+%.1f%% drop power-up" % value
		"crit_chip":
			return "+%d%% crit chance" % int(value)
	return ""
