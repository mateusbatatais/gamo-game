## Lore Cards — cartas colecionáveis estilo álbum de figurinhas, com flavor text
## em primeira pessoa do GAMO. Servem pra contar a história da Coleção Eterna
## em pedacinhos + alinhamento com Gamo (plataforma de colecionismo).
##
## Cards se desbloqueiam automaticamente via eventos do EventBus:
## boss defeated, achievement unlocked, runs concluídas, marcos de progressão.
extends Node

enum Rarity { COMMON, RARE, SPECIAL, LEGENDARY }

class LoreCardDef:
	var id: String
	var title: String
	var subtitle: String  ## ex: "ERA 16-BIT" ou "ESTRATÉGIA"
	var body: String      ## flavor text em 1ª pessoa do GAMO
	var rarity: int
	var accent: Color
	## Closure que retorna true se a carta já deve estar desbloqueada
	## (chamado nos eventos relevantes do EventBus).
	var unlock_check: Callable

	func _init(
		p_id: String,
		p_title: String,
		p_subtitle: String,
		p_body: String,
		p_rarity: int,
		p_accent: Color,
		p_check: Callable
	) -> void:
		id = p_id
		title = p_title
		subtitle = p_subtitle
		body = p_body
		rarity = p_rarity
		accent = p_accent
		unlock_check = p_check


var _registry: Dictionary = {}
var _order: Array[String] = []


func _ready() -> void:
	_register_all()
	# Hooks pra checar unlock após eventos relevantes.
	EventBus.boss_defeated.connect(_recheck_no_arg)
	EventBus.achievement_unlocked.connect(_recheck_with_arg)
	EventBus.run_ended.connect(_recheck_run_ended)
	EventBus.combo_changed.connect(_recheck_with_arg)


func _register_all() -> void:
	_add(LoreCardDef.new(
		"coleção_eterna",
		"A Coleção Eterna",
		"GAMO.LOG #001",
		"Todo cartucho que já existiu vive aqui. Eu fui despertado pra protegê-la. " \
		+ "Não vou falhar.",
		Rarity.COMMON,
		Color("#9bbc0f"),
		func(): return true  # carta inicial, sempre desbloqueada
	))
	_add(LoreCardDef.new(
		"primeiro_glitch",
		"Primeiro Glitch",
		"GAMO.LOG #002",
		"Detectei o vírus antes que ele consumisse meu primeiro cartucho. " \
		+ "Catalogação iniciada.",
		Rarity.COMMON,
		Color("#9bbc0f"),
		func(): return GameState.total_kills >= 1
	))
	_add(LoreCardDef.new(
		"fragmentation_purged",
		"Fragmentation",
		"ERA 16-BIT — BOSS",
		"O primeiro corruptor caiu. Era um cristal mutado, alimentado por bits perdidos. " \
		+ "Pedaços ainda flutuam no arquivo, inofensivos agora.",
		Rarity.RARE,
		Color("#5e35b1"),
		func(): return "era_16bit" in GameState.bosses_defeated
	))
	_add(LoreCardDef.new(
		"bad_sector_purged",
		"Bad Sector",
		"ERA 32-BIT CD — BOSS",
		"Um setor de disco corrompido, girando eternamente. Quando o silenciei, " \
		+ "a era CD voltou a se ler sem ruído.",
		Rarity.RARE,
		Color("#00e5ff"),
		func(): return "era_32bit_cd" in GameState.bosses_defeated
	))
	_add(LoreCardDef.new(
		"polygon_hell_purged",
		"Polygon Hell",
		"ERA 64-BIT — BOSS FINAL",
		"A pirâmide do colapso poligonal. Convocava Hulks de hardware antigo " \
		+ "como soldados. Hoje, repousa cataloged como artefato lendário.",
		Rarity.LEGENDARY,
		Color("#7e57c2"),
		func(): return "era_64bit" in GameState.bosses_defeated
	))
	_add(LoreCardDef.new(
		"streak_lacrada",
		"Sequência Lacrada",
		"MARCO — COMBO 25",
		"Ritmo perfeito. Cada tiro entrando como peça de puzzle. " \
		+ "A coleção respira melhor quando eu não erro.",
		Rarity.SPECIAL,
		Color("#ffeb3b"),
		func(): return GameState.max_combo_ever >= 25
	))
	_add(LoreCardDef.new(
		"mint_condition",
		"Mint Condition",
		"MARCO — COMBO 100",
		"Selo intacto. Sem amassados. Cem hits sem falhar nem uma. " \
		+ "Isso aqui vai pra prateleira de exibição.",
		Rarity.LEGENDARY,
		Color("#ffeb3b"),
		func(): return GameState.max_combo_ever >= 100
	))
	_add(LoreCardDef.new(
		"caçador_de_bugs",
		"Caçador de Bugs",
		"MARCO — 100 ABATES",
		"Cem corruptors apagados. Eu mantenho cada registro — quem caiu, quando, " \
		+ "onde. O arquivo é fato, não memória.",
		Rarity.COMMON,
		Color("#9bbc0f"),
		func(): return GameState.total_kills >= 100
	))
	_add(LoreCardDef.new(
		"catalogador_iniciante",
		"Catalogador Iniciante",
		"MARCO — 1.000 ABATES",
		"Mil entradas no banco de dados. Eu não esqueço de nenhum. " \
		+ "Esse arquivo vai sobreviver mais que eu.",
		Rarity.RARE,
		Color("#9bbc0f"),
		func(): return GameState.total_kills >= 1000
	))
	_add(LoreCardDef.new(
		"defensor_eterno",
		"Defensor da Coleção Eterna",
		"FIM DA TRILOGIA",
		"Três eras purificadas. Três corruptors arquivados. A Coleção dorme em paz " \
		+ "— por enquanto. Sempre tem mais um glitch.",
		Rarity.LEGENDARY,
		Color("#00e5ff"),
		func(): return GameState.bosses_defeated.size() >= 3
	))
	_add(LoreCardDef.new(
		"estante_cheia",
		"Estante Cheia",
		"MARCO — 10 CARTUCHOS",
		"Dez cartuchos diferentes na minha estante. Cada um conta uma história " \
		+ "da era dele. Eu sou o bibliotecário e o guerreiro.",
		Rarity.SPECIAL,
		Color("#00e5ff"),
		func(): return GameState.collected_cartridges.size() >= 10
	))
	_add(LoreCardDef.new(
		"gamo_origin",
		"Despertar do GAMO",
		"GAMO.LOG #000",
		"Eu sou GAMO — Guardian of Archived Memorabilia Online. " \
		+ "Ativado por uma plataforma chamada gamo.games quando o Glitch atacou.",
		Rarity.SPECIAL,
		Color("#00e5ff"),
		func(): return GameState.total_runs >= 3
	))


func _add(def: LoreCardDef) -> void:
	_registry[def.id] = def
	_order.append(def.id)


func get_def(id: String) -> LoreCardDef:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	return _order.duplicate()


func is_collected(id: String) -> bool:
	return id in GameState.collected_lore_cards


## Verifica todas as cartas e desbloqueia as que atingiram a condição.
## Emite signal individual pra cada nova carta (pro toast aparecer).
func _check_all_unlocks() -> void:
	for id in _order:
		if is_collected(id):
			continue
		var def: LoreCardDef = _registry[id]
		if def.unlock_check.call():
			GameState.unlock_lore_card(id)


func _recheck_no_arg() -> void:
	_check_all_unlocks()


func _recheck_with_arg(_a) -> void:
	_check_all_unlocks()


func _recheck_run_ended(_v: bool, _stats: Dictionary) -> void:
	_check_all_unlocks()


func rarity_color(rarity: int) -> Color:
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


func rarity_label(rarity: int) -> String:
	match rarity:
		Rarity.COMMON:
			return "COMUM"
		Rarity.RARE:
			return "RARA"
		Rarity.SPECIAL:
			return "ESPECIAL"
		Rarity.LEGENDARY:
			return "LENDÁRIA"
	return "???"
