## Registro de upgrades permanentes comprados na hub com Tokens de Memória.
## Cada upgrade tem id, label, max_level, custo base, custo por nível, e um
## efeito aplicado ao player no início da run via apply_to_player().
extends Node

class UpgradeDef:
	var id: String
	var display_name: String
	var description: String
	var max_level: int
	var base_cost: int
	var cost_per_level: int  ## custo += cost_per_level * current_level

	func _init(
		p_id: String,
		p_name: String,
		p_desc: String,
		p_max: int,
		p_base_cost: int,
		p_cost_per: int
	) -> void:
		id = p_id
		display_name = p_name
		description = p_desc
		max_level = p_max
		base_cost = p_base_cost
		cost_per_level = p_cost_per


var _registry: Dictionary = {}
var _order: Array[String] = []


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	_add(UpgradeDef.new(
		"max_hp", "HP Máximo",
		"+10% de HP máximo por nível.", 10, 15, 5
	))
	_add(UpgradeDef.new(
		"damage", "Dano",
		"+5% de dano em tudo por nível.", 10, 20, 8
	))
	_add(UpgradeDef.new(
		"xp_gain", "XP Ganho",
		"+10% de XP por gema coletada.", 5, 25, 15
	))
	_add(UpgradeDef.new(
		"magnet", "Alcance do Magnet",
		"+15% de raio de coleta por nível.", 5, 20, 10
	))
	_add(UpgradeDef.new(
		"crit_chance", "Chance de Crítico",
		"+3% de chance de crítico por nível.", 8, 30, 12
	))
	_add(UpgradeDef.new(
		"dash_cooldown", "Cooldown do Dash",
		"-8% no cooldown do dash por nível.", 5, 25, 12
	))


func _add(def: UpgradeDef) -> void:
	_registry[def.id] = def
	_order.append(def.id)


func get_def(id: String) -> UpgradeDef:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	return _order.duplicate()


## Custo do PRÓXIMO nível (ou -1 se já maxado).
func cost_for_next(id: String) -> int:
	var def := get_def(id)
	if def == null:
		return -1
	var lvl: int = GameState.get_upgrade_level(id)
	if lvl >= def.max_level:
		return -1
	return def.base_cost + def.cost_per_level * lvl


## Aplica todos os upgrades comprados aos stats do player. Chamado pelo Arena
## logo após spawnar o player.
func apply_to_player(player: Player) -> void:
	var hp_lvl: int = GameState.get_upgrade_level("max_hp")
	if hp_lvl > 0:
		var new_max: int = int(round(float(player.max_hp) * (1.0 + 0.10 * hp_lvl)))
		player.max_hp = new_max
		player.current_hp = new_max

	var dmg_lvl: int = GameState.get_upgrade_level("damage")
	if dmg_lvl > 0:
		player.damage_mult *= (1.0 + 0.05 * dmg_lvl)

	var magnet_lvl: int = GameState.get_upgrade_level("magnet")
	if magnet_lvl > 0:
		player.pickup_radius_mult *= (1.0 + 0.15 * magnet_lvl)

	var crit_lvl: int = GameState.get_upgrade_level("crit_chance")
	if crit_lvl > 0:
		player.crit_chance = clampf(player.crit_chance + 0.03 * crit_lvl, 0.0, 1.0)

	var dash_lvl: int = GameState.get_upgrade_level("dash_cooldown")
	if dash_lvl > 0:
		player.dash_max_cooldown *= (1.0 - 0.08 * dash_lvl)


## Multiplicador de XP a ser usado pelo XpSystem ao coletar gemas.
func get_xp_multiplier() -> float:
	var lvl: int = GameState.get_upgrade_level("xp_gain")
	return 1.0 + 0.10 * float(lvl)
