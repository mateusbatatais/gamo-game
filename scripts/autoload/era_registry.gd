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

# Era 2 — 32-bit CD: paleta iridescente "óleo no disco"
const PALETTE_ERA_32BIT := {
	"bg_top": Color("#0a1a3a"),     # azul-noite CD
	"bg_bottom": Color("#1a0a2a"),  # roxo-disco
	"grid": Color("#5e35b1"),
	"scan": Color(0, 0, 0, 0.14),
}

# Era 3 — 64-bit: pastel + cinza fog (low-poly aesthetic)
const PALETTE_ERA_64BIT := {
	"bg_top": Color("#37474f"),     # cinza-azulado
	"bg_bottom": Color("#1a0033"),  # roxo-poligonal
	"grid": Color("#7e57c2"),
	"scan": Color(0, 0, 0, 0.10),
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
		"Fragmentation"
	))
	_add(EraDef.new(
		"era_32bit_cd",
		"Era 32-bit CD",
		"O Glitch invadiu a era do disco óptico. Polígonos e arranhões.",
		PALETTE_ERA_32BIT,
		[
			["polygon",      0.0, 0.7],
			["scratch",      0.0, 0.5],
			["fmv",         20.0, 0.6],
			["compression",  0.0, 0.5],   # legado da era anterior
			["null_sprite", 60.0, 0.5],
			["bit_flip",   120.0, 0.5],
			["memory_leak",150.0, 0.4],
		],
		"BadSector",
		"Bad Sector",
		"Derrote Fragmentation na Era 16-bit"
	))
	_add(EraDef.new(
		"era_64bit",
		"Era 64-bit",
		"Polígonos pseudo-3D, fog distance, z-fighting. Pior pesadelo do hardware antigo.",
		PALETTE_ERA_64BIT,
		[
			["wireframe_hulk", 0.0, 0.5],
			["z_fight",        0.0, 0.7],
			["polygon",        0.0, 0.5],  # legado da era anterior
			["fmv",            0.0, 0.4],
			["null_sprite",   30.0, 0.4],
			["bit_flip",      80.0, 0.5],
			["memory_leak",  120.0, 0.4],
			["compression",  150.0, 0.4],
		],
		"PolygonHell",
		"Polygon Hell",
		"Derrote Bad Sector na Era 32-bit CD"
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
	# Eras da progressão sempre liberadas (avançam automaticamente).
	if id == "era_16bit" or id == "era_32bit_cd" or id == "era_64bit":
		return true
	if id == "era_8bit":
		return true
	return false


## Lista ordenada de eras que compõem uma run completa.
## Agora 3 fases: 16-bit → 32-bit CD → 64-bit (boss final Polygon Hell).
func run_progression() -> Array[String]:
	return ["era_16bit", "era_32bit_cd", "era_64bit"]
