## Codex/Arquivo: descrições de inimigos e bosses pra exibir no painel da hub.
## Cada entry guarda referência DIRETA aos frames + paleta (constantes de Sprites).
## Visibilidade controlada via GameState.encountered_enemies.
extends Node

class CodexEntry:
	var id: String
	var display_name: String
	var category: String  ## "ENEMY", "MINIBOSS", "BOSS"
	var description: String  ## comportamento mecânico (1-2 linhas)
	var lore: String  ## biografia in-universe (opcional, 2-4 linhas em 1ª pessoa do GAMO)
	var sprite_frames: Array  ## referência direta aos frames ASCII
	var palette: Dictionary

	func _init(
		p_id: String,
		p_name: String,
		p_category: String,
		p_desc: String,
		p_frames: Array,
		p_palette: Dictionary,
		p_lore: String = ""
	) -> void:
		id = p_id
		display_name = p_name
		category = p_category
		description = p_desc
		sprite_frames = p_frames
		palette = p_palette
		lore = p_lore


var _registry: Dictionary = {}
var _order: Array[String] = []


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	_add(CodexEntry.new("artifact", "Artifact", "ENEMY",
		"Pixel verde piscando. Caminhada lenta direto no alvo. O bug mais básico.",
		Sprites.ARTIFACT_IDLE, Sprites.PALETTE_ARTIFACT,
		"Pixel solitário, talvez tenha sido um sprite legítimo. Hoje vaga, " +
		"perdido em um loop de busca pelo cartucho de origem."))
	_add(CodexEntry.new("tear", "Tear", "ENEMY",
		"Linhas horizontais de tearing que atravessam a tela rápido. Frágil, mas em massa machuca.",
		Sprites.TEAR_IDLE, Sprites.PALETTE_TEAR,
		"Vsync rompida. Cada Tear é uma fração de frame que perdeu o trem da renderização — " +
		"corta a realidade buscando o anterior."))
	_add(CodexEntry.new("ascii_swarm", "ASCII Swarm", "ENEMY",
		"Caracteres voadores em enxame errático. Sozinhos são nada, juntos viram nuvem.",
		Sprites.SWARM_IDLE, Sprites.PALETTE_SWARM,
		"Restos de console de debug que escaparam do log. Cada caractere lembra vagamente " +
		"que já significou alguma coisa. Agora só zumbem."))
	_add(CodexEntry.new("bleed", "Bleed", "ENEMY",
		"Blob roxo deixando rastros de stain por onde passa. Cuidado com as pegadas.",
		Sprites.BLEED_IDLE, Sprites.PALETTE_BLEED,
		"Memória que vazou pra setores adjacentes. Cada passo dele contamina " +
		"o solo — é por isso que catalogamos cartuchos em ambiente controlado."))
	_add(CodexEntry.new("null_sprite", "Null Sprite", "ENEMY",
		"Quadrado missing-texture magenta. Tank — alto HP e dano absurdo de contato.",
		Sprites.NULL_IDLE, Sprites.PALETTE_NULL,
		"Asset que perdeu sua textura mas manteve a colisão. Sólido demais pra um nada — " +
		"o vácuo aprendeu a tropeçar com força."))
	_add(CodexEntry.new("echo", "Echo", "ENEMY",
		"Cópia distorcida de você mesmo. Reproduz seus movimentos com atraso de 1.5s.",
		Sprites.ECHO_IDLE, Sprites.PALETTE_ECHO,
		"Frame buffer antigo onde minha própria silhueta ficou presa. " +
		"Não é exatamente eu — é o que eu fui há 1,5 segundos atrás."))
	_add(CodexEntry.new("checksum", "Checksum", "ENEMY",
		"Turret hexagonal. Mantém distância e dispara projéteis precisos.",
		Sprites.CHECKSUM_IDLE, Sprites.PALETTE_CHECKSUM,
		"Validador de integridade que enlouqueceu. Acredita que toda forma " +
		"de vida é um hash errado e tenta corrigir com fogo."))
	_add(CodexEntry.new("memory_leak", "Memory Leak", "ENEMY",
		"Cresce com o tempo, ocupando espaço. Ao morrer libera 3 ASCII Swarms.",
		Sprites.LEAK_IDLE, Sprites.PALETTE_LEAK,
		"Alocação esquecida no heap. Quanto mais tempo eu deixo ele rondar, " +
		"mais memória ele consome. Não dá pra ignorar."))
	_add(CodexEntry.new("hue_shift", "Hue Shift", "ENEMY",
		"Cicla matizes a cada 0.4s. Disco-bug que confunde o olho.",
		Sprites.HUE_SHIFT_IDLE, Sprites.PALETTE_HUE_SHIFT,
		"Um sprite cuja paleta foi corrompida e gira em loop infinito. " +
		"Bonito de assistir até virar dano."))
	_add(CodexEntry.new("compression", "Compression", "ENEMY",
		"Bloco JPG-style que teleporta perto de você a cada 2.5s. Não persegue, só pisca.",
		Sprites.COMPRESSION_IDLE, Sprites.PALETTE_COMPRESSION,
		"Artifact de compressão lossy. Não tem trajetória contínua — pula " +
		"entre quadrantes da grade, sempre um pouco mais perto."))
	_add(CodexEntry.new("sprite_limit", "Sprite Limit", "ENEMY",
		"Tem chance de dividir em duas cópias quando atingido. Reza pra não maxar gerações.",
		Sprites.SPRITE_LIMIT_IDLE, Sprites.PALETTE_SPRITE_LIMIT,
		"Lembrança do limite de 64 sprites por scanline do SNES. Quando " +
		"a arena enche, esse cara faz a engine implorar por perdão."))
	_add(CodexEntry.new("bit_flip", "Bit Flip", "ENEMY",
		"Alterna entre ON (vulnerável) e OFF (imune). Mira bem os hits.",
		Sprites.BIT_FLIP_IDLE, Sprites.PALETTE_BIT_FLIP_ON,
		"Radiação cósmica num bit instável. Existe e não existe — em ciclo. " +
		"Cataloguei ele duas vezes, depois apaguei uma entrada por dúvida."))
	_add(CodexEntry.new("mini_boss", "Sentinel", "MINIBOSS",
		"Mini-boss que aparece em waves. HP alto, dispara ring de projéteis. Dropa health + power-up + boon.",
		Sprites.MINIBOSS_IDLE, Sprites.PALETTE_MINIBOSS,
		"Sentinela de cartucho. Antes da corrupção, vigiava saves contra " +
		"travamentos. Hoje patrulha por hábito, sem lembrar do que protegia."))
	_add(CodexEntry.new("fragmentation", "Fragmentation", "BOSS",
		"Boss da Era 16-bit. 4 fases: Whole, Cracked, Shattered, Final. Dropa o lendário Region Free.",
		Sprites.FRAGMENTATION_IDLE, Sprites.PALETTE_FRAGMENTATION,
		"O primeiro corruptor de cartucho que eu já registrei. Era um cristal " +
		"de save inteiro, alimentado por bits perdidos. Quebrou em 4 fases — " +
		"cada uma mais agressiva que a anterior. Cataloguei como caso #001."))
	# Era 32-bit CD
	_add(CodexEntry.new("polygon", "Polygon", "ENEMY",
		"Triângulo pseudo-3D rápido que persegue rotacionando. Frágil, mas em massa machuca.",
		Sprites.POLYGON_IDLE, Sprites.PALETTE_POLYGON,
		"Os primeiros triângulos que aprenderam a virar para sempre olhar pra câmera. " +
		"Frágeis mas em bando — como peixes. Pioneiros da era 3D, hoje só zumbis dela."))
	_add(CodexEntry.new("scratch", "Scratch", "ENEMY",
		"Risco horizontal de CD arranhado. Anda só na horizontal em alta velocidade.",
		Sprites.SCRATCH_IDLE, Sprites.PALETTE_SCRATCH,
		"Cicatriz de mídia óptica que aprendeu a se mover. Lembra do tempo em " +
		"que jogos podiam morrer porque alguém deixou um copo molhado no encarte."))
	_add(CodexEntry.new("fmv", "FMV Burst", "ENEMY",
		"Bloco de vídeo full-motion corrompido. 'Buffera' periodicamente e dispara cruz cardinal.",
		Sprites.FMV_IDLE, Sprites.PALETTE_FMV,
		"Cutscene Full Motion Video que esqueceu como terminar. Buffera tentando " +
		"carregar o próximo segundo. Quando dá timeout, cospe artefatos cardinais."))
	_add(CodexEntry.new("bad_sector", "Bad Sector", "BOSS",
		"Boss da Era 32-bit CD. Setor corrompido orbitando, lasers radiais e teleport skip.",
		Sprites.BAD_SECTOR_IDLE, Sprites.PALETTE_BAD_SECTOR,
		"Um setor de disco que rangiu tanto que virou criatura. Gira eternamente em " +
		"busca do head de leitura que nunca volta. Quando o silenciei, a era CD " +
		"voltou a se ler sem ruído. Caso #002."))
	# Era 64-bit
	_add(CodexEntry.new("wireframe_hulk", "Wireframe Hulk", "ENEMY",
		"Tank pseudo-3D pesado. HP alto, dano de contato brutal, movimento lento.",
		Sprites.WIREFRAME_IDLE, Sprites.PALETTE_WIREFRAME,
		"Modelo 3D que perdeu suas texturas e ficou só nas arestas. Carrega o peso " +
		"do polígono original. Tudo o que sobrou dele é a estrutura."))
	_add(CodexEntry.new("z_fight", "Z-Fight", "ENEMY",
		"Sprite com flicker entre 2 frames distintos. Move-se em zigue-zague de z-fighting.",
		Sprites.ZFIGHT_IDLE, Sprites.PALETTE_ZFIGHT,
		"Dois polígonos disputando a mesma coordenada de profundidade. Eternamente " +
		"em flicker porque nenhum cede. Olhar pra eles muito tempo dá dor de cabeça."))
	_add(CodexEntry.new("polygon_hell", "Polygon Hell", "BOSS",
		"Boss FINAL. Pirâmide corrompida rotacionando. Espirais, volleys triangulares e convoca Hulks.",
		Sprites.POLYGON_HELL_IDLE, Sprites.PALETTE_POLYGON_HELL,
		"A pirâmide do colapso. Quando o motor 3D ficou velho, ela absorveu o que " +
		"sobrou dos polígonos abandonados. Convoca Hulks de hardware antigo como " +
		"soldados. Foi o boss mais difícil de catalogar. Caso #003 — encerrado."))


func _add(entry: CodexEntry) -> void:
	_registry[entry.id] = entry
	_order.append(entry.id)


func get_entry(id: String) -> CodexEntry:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	return _order.duplicate()


## Gera a textura de preview de uma entry. Tipos explícitos pra não disparar
## o warning de "variable type inferred from Variant" no Godot 4 strict.
func make_preview(entry: CodexEntry) -> ImageTexture:
	if entry == null:
		return null
	return PixelArt.make_sprite(PackedStringArray(entry.sprite_frames[0]), entry.palette)
