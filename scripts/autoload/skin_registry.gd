## Skins do GAMO — variações de paleta sobre os mesmos sprites tier 1/2/3.
## Cada skin tem condição de unlock (auto-detectada no _ready) e aplica
## paleta no Player via Player.spirit_palette antes do _build_sprite.
extends Node

class SkinDef:
	var id: String
	var display_name: String
	var description: String
	var palette: Dictionary
	## Callable que retorna true se a skin já deve estar disponível.
	var auto_unlock_check: Callable
	## Texto explicando como desbloquear (mostrado em skins bloqueadas).
	var unlock_hint: String
	## Sprite frames customizado. Se vazio, usa Sprites.GAMO_T1_IDLE (default).
	## Skins de palette-only (veteran, lacrado, etc) deixam isso vazio.
	## Skins de personagem completo (hacker, chubby, wizard) sobrescrevem.
	var sprite_frames: Array = []

	func _init(
		p_id: String,
		p_name: String,
		p_desc: String,
		p_palette: Dictionary,
		p_check: Callable,
		p_hint: String,
		p_sprite_frames: Array = []
	) -> void:
		id = p_id
		display_name = p_name
		description = p_desc
		palette = p_palette
		auto_unlock_check = p_check
		unlock_hint = p_hint
		sprite_frames = p_sprite_frames


var _registry: Dictionary = {}
var _order: Array[String] = []


func _ready() -> void:
	_register_all()
	# Re-checa unlocks sempre que GameState muda (achievement, kill, etc).
	EventBus.achievement_unlocked.connect(_recheck)
	EventBus.run_ended.connect(_recheck_run)
	_recheck("")


func _register_all() -> void:
	# Default — azul/branco/amarelo Gamo
	_add(SkinDef.new(
		"default", "Padrão",
		"Mascote oficial Gamo. Azul, branco e amarelo.",
		Sprites.PALETTE_GAMO,
		func(): return true,
		""
	))
	# Veterano — verde/cinza retro
	_add(SkinDef.new(
		"veteran", "Veterano",
		"Tons retrô Game Boy. Para quem já mediu forças com o Glitch.",
		{
			"#": Color("#306230"), "=": Color("#0f380f"),
			"L": Color("#9bbc0f"), "o": Color("#9bbc0f"),
			"O": Color("#ffffff"), "x": Color("#ff9800"),
			"-": Color("#000000"),
		},
		func(): return GameState.bosses_defeated.size() >= 1,
		"Derrote o boss Fragmentation."
	))
	# Lacrado — dourado/preto edição limitada
	_add(SkinDef.new(
		"lacrado", "Lacrado",
		"Edição limitada. Banhada em ouro 24k digital.",
		{
			"#": Color("#bf8f30"), "=": Color("#5a3f10"),
			"L": Color("#ffd54f"), "o": Color("#ffeb3b"),
			"O": Color("#ffffff"), "x": Color("#ff5252"),
			"-": Color("#0a0a14"),
		},
		func(): return GameState.max_combo_ever >= 50,
		"Faça um combo de 50 hits (Box Completo)."
	))
	# Mint Condition — branco/ciano gélido
	_add(SkinDef.new(
		"mint", "Mint Condition",
		"Estado perfeito. Selo intacto, sem amassados.",
		{
			"#": Color("#e3f2fd"), "=": Color("#90caf9"),
			"L": Color("#00bcd4"), "o": Color("#00e5ff"),
			"O": Color("#ffffff"), "x": Color("#ff9800"),
			"-": Color("#0d47a1"),
		},
		func(): return GameState.max_combo_ever >= 100,
		"Faça um combo de 100 hits (Mint Condition)."
	))
	# Glitch — magenta/cyan corrompido
	_add(SkinDef.new(
		"glitch", "Corrupção",
		"GAMO foi tocado pelo Glitch. Cores invertidas e instáveis.",
		{
			"#": Color("#e040fb"), "=": Color("#000000"),
			"L": Color("#00e5ff"), "o": Color("#ff00ff"),
			"O": Color("#ffffff"), "x": Color("#ffeb3b"),
			"-": Color("#1a0033"),
		},
		func(): return GameState.total_kills >= 1000,
		"Acumule 1.000 abates totais (Catalogador Iniciante)."
	))
	# Konami — vermelho/branco/azul tipo controle clássico (easter egg)
	_add(SkinDef.new(
		"konami", "Cheat Code",
		"30 vidas no estilo dos clássicos. Você sabe o código.",
		{
			"#": Color("#d32f2f"), "=": Color("#7f0000"),
			"L": Color("#ffffff"), "o": Color("#ff5252"),
			"O": Color("#ffeb3b"), "x": Color("#0d47a1"),
			"-": Color("#000000"),
		},
		func(): return GameState.konami_unlocked,
		"Acorde o código que dorme nos clássicos."
	))
	# --- Personagens alternativos (sprite + paleta próprios) ---
	_add(SkinDef.new(
		"hacker", "Hacker",
		"Decifradora do código corrompido. Óculos antirreflexo + moletom da gamo.",
		Sprites.PALETTE_HACKER,
		func(): return GameState.total_kills >= 250,
		"Acumule 250 abates totais.",
		Sprites.HACKER_IDLE
	))
	_add(SkinDef.new(
		"chubby", "Gamer Retrô",
		"Veterano de cartucho. Mais HP, vibe nostálgica.",
		Sprites.PALETTE_CHUBBY,
		func(): return GameState.total_runs >= 10,
		"Complete 10 runs (vitória ou derrota).",
		Sprites.CHUBBY_IDLE
	))
	_add(SkinDef.new(
		"wizard", "Mago do Codex",
		"Sussurra incantamentos em assembly. Conjura damage do nada.",
		Sprites.PALETTE_WIZARD,
		func(): return GameState.collected_lore_cards.size() >= 6,
		"Colete 6 lore cards (metade do álbum).",
		Sprites.WIZARD_IDLE
	))


func _add(def: SkinDef) -> void:
	_registry[def.id] = def
	_order.append(def.id)


func get_def(id: String) -> SkinDef:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	return _order.duplicate()


func is_unlocked(id: String) -> bool:
	return id in GameState.unlocked_skins


func active_palette() -> Dictionary:
	var def: SkinDef = get_def(GameState.current_skin_id)
	if def == null:
		def = get_def("default")
	if def == null:
		return Sprites.PALETTE_GAMO
	return def.palette


## Retorna os sprite frames da skin ativa. Skins de palette-only retornam
## os frames default do GAMO; skins de personagem retornam os próprios.
func active_sprite_frames() -> Array:
	var def: SkinDef = get_def(GameState.current_skin_id)
	if def != null and not def.sprite_frames.is_empty():
		return def.sprite_frames
	return Sprites.GAMO_T1_IDLE


## Frames de uma skin específica (usado pra preview na hub).
func sprite_frames_of(skin_id: String) -> Array:
	var def: SkinDef = get_def(skin_id)
	if def != null and not def.sprite_frames.is_empty():
		return def.sprite_frames
	return Sprites.GAMO_T1_IDLE


func _recheck(_a: Variant = null) -> void:
	for id in _order:
		var def: SkinDef = _registry[id]
		if not is_unlocked(id) and def.auto_unlock_check.call():
			GameState.unlock_skin(id)


func _recheck_run(_v: bool, _stats: Dictionary) -> void:
	_recheck(null)
