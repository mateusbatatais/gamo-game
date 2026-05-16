## Codex/Arquivo: descrições de inimigos e bosses pra exibir no painel da hub.
## Cada entry guarda referência DIRETA aos frames + paleta (constantes de Sprites).
## Visibilidade controlada via GameState.encountered_enemies.
extends Node

class CodexEntry:
	var id: String
	var display_name: String
	var category: String  ## "ENEMY", "MINIBOSS", "BOSS"
	var description: String
	var sprite_frames: Array  ## referência direta aos frames ASCII
	var palette: Dictionary

	func _init(
		p_id: String,
		p_name: String,
		p_category: String,
		p_desc: String,
		p_frames: Array,
		p_palette: Dictionary
	) -> void:
		id = p_id
		display_name = p_name
		category = p_category
		description = p_desc
		sprite_frames = p_frames
		palette = p_palette


var _registry: Dictionary = {}
var _order: Array[String] = []


func _ready() -> void:
	_register_all()


func _register_all() -> void:
	_add(CodexEntry.new("artifact", "Artifact", "ENEMY",
		"Pixel verde piscando. Caminhada lenta direto no alvo. O bug mais básico.",
		Sprites.ARTIFACT_IDLE, Sprites.PALETTE_ARTIFACT))
	_add(CodexEntry.new("tear", "Tear", "ENEMY",
		"Linhas horizontais de tearing que atravessam a tela rápido. Frágil, mas em massa machuca.",
		Sprites.TEAR_IDLE, Sprites.PALETTE_TEAR))
	_add(CodexEntry.new("ascii_swarm", "ASCII Swarm", "ENEMY",
		"Caracteres voadores em enxame errático. Sozinhos são nada, juntos viram nuvem.",
		Sprites.SWARM_IDLE, Sprites.PALETTE_SWARM))
	_add(CodexEntry.new("bleed", "Bleed", "ENEMY",
		"Blob roxo deixando rastros de stain por onde passa. Cuidado com as pegadas.",
		Sprites.BLEED_IDLE, Sprites.PALETTE_BLEED))
	_add(CodexEntry.new("null_sprite", "Null Sprite", "ENEMY",
		"Quadrado missing-texture magenta. Tank — alto HP e dano absurdo de contato.",
		Sprites.NULL_IDLE, Sprites.PALETTE_NULL))
	_add(CodexEntry.new("echo", "Echo", "ENEMY",
		"Cópia distorcida de você mesmo. Reproduz seus movimentos com atraso de 1.5s.",
		Sprites.ECHO_IDLE, Sprites.PALETTE_ECHO))
	_add(CodexEntry.new("checksum", "Checksum", "ENEMY",
		"Turret hexagonal. Mantém distância e dispara projéteis precisos.",
		Sprites.CHECKSUM_IDLE, Sprites.PALETTE_CHECKSUM))
	_add(CodexEntry.new("memory_leak", "Memory Leak", "ENEMY",
		"Cresce com o tempo, ocupando espaço. Ao morrer libera 3 ASCII Swarms.",
		Sprites.LEAK_IDLE, Sprites.PALETTE_LEAK))
	_add(CodexEntry.new("hue_shift", "Hue Shift", "ENEMY",
		"Cicla matizes a cada 0.4s. Disco-bug que confunde o olho.",
		Sprites.HUE_SHIFT_IDLE, Sprites.PALETTE_HUE_SHIFT))
	_add(CodexEntry.new("compression", "Compression", "ENEMY",
		"Bloco JPG-style que teleporta perto de você a cada 2.5s. Não persegue, só pisca.",
		Sprites.COMPRESSION_IDLE, Sprites.PALETTE_COMPRESSION))
	_add(CodexEntry.new("sprite_limit", "Sprite Limit", "ENEMY",
		"Tem chance de dividir em duas cópias quando atingido. Reza pra não maxar gerações.",
		Sprites.SPRITE_LIMIT_IDLE, Sprites.PALETTE_SPRITE_LIMIT))
	_add(CodexEntry.new("bit_flip", "Bit Flip", "ENEMY",
		"Alterna entre ON (vulnerável) e OFF (imune). Mira bem os hits.",
		Sprites.BIT_FLIP_IDLE, Sprites.PALETTE_BIT_FLIP_ON))
	_add(CodexEntry.new("mini_boss", "Sentinel", "MINIBOSS",
		"Mini-boss que aparece em waves. HP alto, dispara ring de projéteis. Dropa health + power-up.",
		Sprites.MINIBOSS_IDLE, Sprites.PALETTE_MINIBOSS))
	_add(CodexEntry.new("fragmentation", "Fragmentation", "BOSS",
		"Boss final da Era 16-bit. 4 fases: Whole, Cracked, Shattered, Final. Dropa o lendário Region Free.",
		Sprites.FRAGMENTATION_IDLE, Sprites.PALETTE_FRAGMENTATION))


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
