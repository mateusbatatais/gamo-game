## Registro das Eras (fases) do jogo.
## Cada Era define paleta, lista de inimigos disponíveis, e boss.
extends Node

class EraDef:
	var id: String
	var display_name: String
	var description: String
	var bg_palette: Dictionary   ## chaves "bg_top", "bg_bottom", "grid", "scan"
	## Array de Array[id, unlock_time_seconds, weight]
	var enemy_entries: Array
	var boss_class_name: String
	var boss_display_name: String
	var unlock_label: String

	func _init(
		p_id: String,
		p_name: String,
		p_desc: String,
		p_palette: Dictionary,
		p_entries: Array,
		p_boss_class: String,
		p_boss_name: String,
		p_unlock: String = ""
	) -> void:
		id = p_id
		display_name = p_name
		description = p_desc
		bg_palette = p_palette
		enemy_entries = p_entries
		boss_class_name = p_boss_class
		boss_display_name = p_boss_name
		unlock_label = p_unlock


# --- Paletas de fundo ---
const PALETTE_ERA_8BIT := {
	"bg_top": Color("#0f380f"),
	"bg_bottom": Color("#0f380f"),
	"grid": Color("#306230"),
	"scan": Color(0, 0, 0, 0.18),
}

const PALETTE_ERA_16BIT := {
	"bg_top": Color("#1a237e"),     # azul profundo
	"bg_bottom": Color("#311b92"),  # roxo céu noturno
	"grid": Color("#3949ab"),
	"scan": Color(0, 0, 0, 0.12),
}


var _registry: Dictionary = {}


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	_add(EraDef.new(
		"era_8bit",
		"Era 8-bit",
		"Inicio da Coleção Eterna. Glitches simples mas mortais em grupo.",
		PALETTE_ERA_8BIT,
		[
			["artifact",     0.0, 1.0],
			["tear",        30.0, 0.7],
			["ascii_swarm", 75.0, 0.9],
			["bleed",       90.0, 0.5],
			["null_sprite", 150.0, 0.6],
			["checksum",    180.0, 0.45],
			["echo",        210.0, 0.35],
			["memory_leak", 240.0, 0.3],
		],
		"CorruptionV1",
		"Corruption v1.0"
	))
	_add(EraDef.new(
		"era_16bit",
		"Era 16-bit",
		"Cores e ataques mais ricos. O Glitch evoluiu.",
		PALETTE_ERA_16BIT,
		[
			["artifact",      0.0, 0.5],
			["checksum",      0.0, 0.5],
			["hue_shift",    15.0, 0.9],
			["compression",  60.0, 0.7],
			["null_sprite", 110.0, 0.5],
			["sprite_limit",140.0, 0.6],
			["bit_flip",    190.0, 0.7],
		],
		"Fragmentation",
		"Fragmentation",
		"Derrote Corruption v1.0 na Era 8-bit"
	))


func _add(def: EraDef) -> void:
	_registry[def.id] = def


func get_def(id: String) -> EraDef:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in _registry.keys():
		ids.append(k)
	return ids


func is_unlocked(id: String) -> bool:
	# 8-bit foi removido como opção jogável; 16-bit é a única era ativa e sempre liberada.
	if id == "era_16bit":
		return true
	if id == "era_8bit":
		return true
	return false
