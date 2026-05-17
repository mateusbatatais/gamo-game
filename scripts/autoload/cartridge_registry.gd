## Registro central de todos os cartuchos disponíveis.
## Cartucho = upgrade que o jogador equipa (arma ou passivo).
extends Node

enum CartridgeType { WEAPON, PASSIVE }
enum Rarity { COMMON, RARE, SPECIAL, LEGENDARY }


class CartridgeDef:
	var id: String
	var display_name: String
	var description: String
	var type: CartridgeType
	var rarity: Rarity
	var max_level: int = 5
	var script_path: String  ## Caminho do .gd que implementa o efeito

	func _init(p_id: String, p_name: String, p_desc: String, p_type: CartridgeType, p_rarity: Rarity, p_script: String) -> void:
		id = p_id
		display_name = p_name
		description = p_desc
		type = p_type
		rarity = p_rarity
		script_path = p_script


class EvolutionDef:
	var result_id: String       ## id do cartucho resultante
	var ingredient_a: String    ## cartucho base 1 (precisa estar no max level)
	var ingredient_b: String    ## cartucho base 2 (precisa estar equipado em qualquer level)

	func _init(p_result: String, p_a: String, p_b: String) -> void:
		result_id = p_result
		ingredient_a = p_a
		ingredient_b = p_b


var _registry: Dictionary = {}
var _evolutions: Array[EvolutionDef] = []


func _ready() -> void:
	_register_all()
	_register_evolutions()


func _register_all() -> void:
	_add(CartridgeDef.new(
		"star_blaster",
		"Star Blaster",
		"Projétil reto que voa pra frente do alvo mais próximo.",
		CartridgeType.WEAPON,
		Rarity.COMMON,
		"res://scripts/cartridges/star_blaster.gd"
	))
	_add(CartridgeDef.new(
		"spread_cart",
		"Spread Cart",
		"Dispara 3 projéteis em leque.",
		CartridgeType.WEAPON,
		Rarity.RARE,
		"res://scripts/cartridges/spread_cart.gd"
	))
	_add(CartridgeDef.new(
		"pixel_aura",
		"Pixel Aura",
		"Pixels orbitam você causando dano.",
		CartridgeType.WEAPON,
		Rarity.SPECIAL,
		"res://scripts/cartridges/pixel_aura.gd"
	))
	_add(CartridgeDef.new(
		"power_glove",
		"Power Glove",
		"+25% de dano por nível.",
		CartridgeType.PASSIVE,
		Rarity.COMMON,
		"res://scripts/cartridges/power_glove.gd"
	))
	_add(CartridgeDef.new(
		"save_state",
		"Save State",
		"Revive 1 vez ao morrer.",
		CartridgeType.PASSIVE,
		Rarity.LEGENDARY,
		"res://scripts/cartridges/save_state.gd"
	))
	_add(CartridgeDef.new(
		"reset_button",
		"Reset Button",
		"Cura total ao morrer. Drop lendário do boss.",
		CartridgeType.PASSIVE,
		Rarity.LEGENDARY,
		"res://scripts/cartridges/reset_button.gd"
	))
	# --- Evoluções ---
	_add(CartridgeDef.new(
		"mega_blaster",
		"Mega Blaster",
		"Laser piercing que atravessa fileiras de inimigos.",
		CartridgeType.WEAPON,
		Rarity.LEGENDARY,
		"res://scripts/cartridges/mega_blaster.gd"
	))
	_add(CartridgeDef.new(
		"chaos_field",
		"Chaos Field",
		"Orbitais pulsam disparando projeteis em todas direcoes.",
		CartridgeType.WEAPON,
		Rarity.LEGENDARY,
		"res://scripts/cartridges/chaos_field.gd"
	))
	_add(CartridgeDef.new(
		"iron_save",
		"Iron Save",
		"Revive 2x + ganha +60% dano permanente apos primeiro revive.",
		CartridgeType.PASSIVE,
		Rarity.LEGENDARY,
		"res://scripts/cartridges/iron_save.gd"
	))
	# --- Cartuchos Era 16-bit ---
	_add(CartridgeDef.new(
		"stereo_sound",
		"Stereo Sound",
		"Dispara 2 projeteis paralelos.",
		CartridgeType.WEAPON,
		Rarity.RARE,
		"res://scripts/cartridges/stereo_sound.gd"
	))
	_add(CartridgeDef.new(
		"mode_7_spin",
		"Mode 7 Spin",
		"Projeteis em espiral ao redor de voce.",
		CartridgeType.WEAPON,
		Rarity.SPECIAL,
		"res://scripts/cartridges/mode_7_spin.gd"
	))
	_add(CartridgeDef.new(
		"region_free",
		"Region Free",
		"Projeteis aceleram e piercem multiplos inimigos. Drop do boss 16-bit.",
		CartridgeType.WEAPON,
		Rarity.LEGENDARY,
		"res://scripts/cartridges/region_free.gd"
	))
	# --- Evoluções 16-bit ---
	_add(CartridgeDef.new(
		"sonic_boom",
		"Sonic Boom",
		"4 projeteis paralelos com piercing e dano alto.",
		CartridgeType.WEAPON,
		Rarity.LEGENDARY,
		"res://scripts/cartridges/sonic_boom.gd"
	))
	_add(CartridgeDef.new(
		"vortex_field",
		"Vortex Field",
		"Orbitais maiores + pulsos radiais em espiral.",
		CartridgeType.WEAPON,
		Rarity.LEGENDARY,
		"res://scripts/cartridges/vortex_field.gd"
	))
	# --- Cartuchos Era 32-bit CD (Fase 2 do roadmap) ---
	_add(CartridgeDef.new(
		"heat_seeker",
		"Heat Seeker",
		"Mísseis que perseguem o inimigo mais próximo.",
		CartridgeType.WEAPON,
		Rarity.SPECIAL,
		"res://scripts/cartridges/heat_seeker.gd"
	))
	_add(CartridgeDef.new(
		"boomerang",
		"Boomerang",
		"Projétil que atravessa inimigos, volta e acerta de novo.",
		CartridgeType.WEAPON,
		Rarity.RARE,
		"res://scripts/cartridges/boomerang.gd"
	))
	_add(CartridgeDef.new(
		"reflector",
		"Reflector",
		"Escudos orbitais que destroem projéteis inimigos.",
		CartridgeType.WEAPON,
		Rarity.SPECIAL,
		"res://scripts/cartridges/reflector.gd"
	))


func _register_evolutions() -> void:
	_evolutions = [
		EvolutionDef.new("mega_blaster", "star_blaster", "power_glove"),
		EvolutionDef.new("chaos_field", "pixel_aura", "spread_cart"),
		EvolutionDef.new("iron_save", "save_state", "power_glove"),
		EvolutionDef.new("sonic_boom", "stereo_sound", "power_glove"),
		EvolutionDef.new("vortex_field", "mode_7_spin", "pixel_aura"),
	]


func _add(def: CartridgeDef) -> void:
	_registry[def.id] = def


func get_def(id: String) -> CartridgeDef:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in _registry.keys():
		ids.append(k)
	return ids


## Retorna lista de evoluções disponíveis dado os cartuchos atuais do player.
## Uma evolução está pronta se ingredient_a está no max E ingredient_b está equipado.
func available_evolutions(player_cartridges: Dictionary) -> Array[String]:
	var ready_ids: Array[String] = []
	for evo in _evolutions:
		var a_level: int = player_cartridges.get(evo.ingredient_a, 0)
		var b_level: int = player_cartridges.get(evo.ingredient_b, 0)
		var a_def := get_def(evo.ingredient_a)
		if a_def == null:
			continue
		if a_level >= a_def.max_level and b_level > 0:
			# Não oferecer evolução se já tem
			if player_cartridges.get(evo.result_id, 0) == 0:
				ready_ids.append(evo.result_id)
	return ready_ids


## Peso por raridade no sorteio do level-up.
## Legendaries (revives, principalmente) ficam bem raras pra não trivializar a run.
const RARITY_WEIGHTS := {
	Rarity.COMMON: 5.0,
	Rarity.RARE: 2.5,
	Rarity.SPECIAL: 1.2,
	Rarity.LEGENDARY: 0.35,
}

## Cartuchos que NUNCA aparecem no sorteio (só vêm de drops específicos, ex: boss).
const ROLL_BLACKLIST := ["reset_button"]


## Sorteia 3 cartuchos para oferta de level-up.
## Filtra os que o jogador já maxou. Evoluções têm prioridade — sempre incluídas.
## O sorteio dos restantes usa peso por raridade — legendaries raras.
func roll_choices(player_cartridges: Dictionary, count: int = 3) -> Array[String]:
	var picked: Array[String] = []

	# 1. Evoluções prontas vêm primeiro (até preencher count)
	var evolutions := available_evolutions(player_cartridges)
	for evo_id in evolutions:
		if picked.size() >= count:
			break
		picked.append(evo_id)

	# 2. Resto: cartuchos não maxados, com peso por raridade.
	var available_weights: Dictionary = {}
	var total_weight: float = 0.0
	for id in all_ids():
		if id in picked:
			continue
		if id in ROLL_BLACKLIST:
			continue
		var def := get_def(id)
		if def == null:
			continue
		# Evoluções não aparecem por sorte — só via available_evolutions
		if _is_evolution_result(id):
			continue
		var current_level: int = player_cartridges.get(id, 0)
		if current_level >= def.max_level:
			continue
		var weight: float = RARITY_WEIGHTS.get(def.rarity, 1.0)
		available_weights[id] = weight
		total_weight += weight

	# Sorteia (sem reposição) usando os pesos.
	while picked.size() < count and not available_weights.is_empty():
		var roll: float = randf() * total_weight
		var acc: float = 0.0
		var chosen_id: String = ""
		for id in available_weights.keys():
			acc += available_weights[id]
			if roll <= acc:
				chosen_id = id
				break
		if chosen_id == "":
			chosen_id = available_weights.keys()[0]
		picked.append(chosen_id)
		total_weight -= available_weights[chosen_id]
		available_weights.erase(chosen_id)
	return picked


func _is_evolution_result(cartridge_id: String) -> bool:
	for evo in _evolutions:
		if evo.result_id == cartridge_id:
			return true
	return false


## Retorna ids dos cartuchos consumidos por uma evolução (ingredientes).
func ingredients_for(evolution_result_id: String) -> Array[String]:
	for evo in _evolutions:
		if evo.result_id == evolution_result_id:
			return [evo.ingredient_a, evo.ingredient_b]
	return []


func is_evolution(cartridge_id: String) -> bool:
	return _is_evolution_result(cartridge_id)


func rarity_color(rarity: Rarity) -> Color:
	match rarity:
		Rarity.COMMON:
			return Color("#bdbdbd")
		Rarity.RARE:
			return Color("#4caf50")
		Rarity.SPECIAL:
			return Color("#2196f3")
		Rarity.LEGENDARY:
			return Color("#ffc107")
	return Color.WHITE
