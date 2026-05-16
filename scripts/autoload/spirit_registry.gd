## Registro central de Spirits jogáveis (consoles personificados).
## Cada Spirit tem stats próprios, paleta de cor e cartucho inicial.
extends Node

class SpiritDef:
	var id: String
	var display_name: String
	var description: String
	var base_hp: int
	var base_speed: float
	var sprite_scale: float
	var dash_max_cooldown: float
	var starting_cartridge: String
	var palette: Dictionary
	var sprite_frames: Array  ## ASCII art (vinda de Sprites.*_IDLE)
	var unlock_label: String

	func _init(
		p_id: String,
		p_name: String,
		p_desc: String,
		p_hp: int,
		p_speed: float,
		p_scale: float,
		p_dash_cd: float,
		p_cart: String,
		p_palette: Dictionary,
		p_frames: Array,
		p_unlock: String = ""
	) -> void:
		id = p_id
		display_name = p_name
		description = p_desc
		base_hp = p_hp
		base_speed = p_speed
		sprite_scale = p_scale
		dash_max_cooldown = p_dash_cd
		starting_cartridge = p_cart
		palette = p_palette
		sprite_frames = p_frames
		unlock_label = p_unlock


# O único spirit jogável agora é GAMO (mascote azul/branco/amarelo).
# A paleta efetiva vem de Sprites.PALETTE_GAMO e os frames do tier atual são gerenciados
# pelo Player conforme o nível aumenta — este registro só carrega o estado inicial.

var _registry: Dictionary = {}


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	# Único spirit: o mascote GAMO. Os frames iniciais (tier 1, sem armadura) ficam aqui;
	# a evolução visual por nível é controlada pelo Player.
	_add(SpiritDef.new(
		"pixel",
		"GAMO",
		"Robô mascote da plataforma. Ganha armadura ao subir de nível.",
		100, 150.0, 2.0, 4.0,
		"star_blaster",
		Sprites.PALETTE_GAMO,
		Sprites.GAMO_T1_IDLE
	))


func _add(def: SpiritDef) -> void:
	_registry[def.id] = def


func get_def(id: String) -> SpiritDef:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in _registry.keys():
		ids.append(k)
	return ids


## Verifica se o spirit está desbloqueado dado o progresso do GameState.
func is_unlocked(id: String) -> bool:
	# Único spirit jogável; sempre desbloqueado.
	return id == "pixel"
