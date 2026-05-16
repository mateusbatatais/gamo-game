## Cache de sprites procedurais.
## Todos os sprites do jogo são gerados em código a partir de ASCII art + paleta.
## Esta autoload pré-gera tudo no _ready() pra evitar custo runtime.
extends Node

# --- Paletas ---
# Mascote GAMO: azul + branco + amarelo (cores oficiais)
const PALETTE_GAMO := {
	"#": Color("#1565c0"),  # corpo azul principal
	"=": Color("#0d47a1"),  # azul profundo (sombra/contorno do corpo)
	"L": Color("#64b5f6"),  # azul claro (highlights / placas de armadura)
	"o": Color("#ffeb3b"),  # visor amarelo
	"O": Color("#ffffff"),  # branco interno do visor / olhos
	"x": Color("#ff9800"),  # luz/núcleo de energia laranja
	"-": Color("#000a1f"),  # sombra escura
}

# Mantida pra compatibilidade com Echo (inimigo que mimica o sprite antigo do player).
const PALETTE_PIXEL := {
	"#": Color("#2a2a2a"),
	"=": Color("#5a5a5a"),
	"o": Color("#9bbc0f"),
	"O": Color("#0f380f"),
	"-": Color("#1a1a1a"),
	"L": Color("#306230"),
}

# Armas: gun-metal escuro + cano prateado + ponta amarela
const PALETTE_WEAPON := {
	"#": Color("#263238"),  # corpo da arma
	"=": Color("#90a4ae"),  # barril prateado
	"L": Color("#cfd8dc"),  # detalhe claro
	"o": Color("#ffeb3b"),  # ponta do cano (muzzle)
	"x": Color("#ff9800"),  # núcleo de energia (mega)
}

const PALETTE_ARTIFACT := {
	"#": Color("#00ff41"),  # verde glitch
	"=": Color("#008f1f"),
	".": Color("#003510"),
}

const PALETTE_TEAR := {
	"#": Color("#ff0080"),  # rosa tearing
	"=": Color("#ffffff"),
}

const PALETTE_NULL := {
	"#": Color("#ff00ff"),  # magenta missing-texture
	"=": Color("#000000"),
}

const PALETTE_PROJECTILE := {
	"#": Color("#ffeb3b"),  # amarelo bullet
	"=": Color("#ff9800"),
}

const PALETTE_GEM := {
	"#": Color("#00e5ff"),
	"=": Color("#0099cc"),
	".": Color("#005577"),
}

const PALETTE_BLEED := {
	"#": Color("#c2185b"),  # vermelho-rosa sangrento
	"=": Color("#7b1f3b"),  # vermelho mais escuro
	"o": Color("#ff5252"),  # destaque brilhante
}

const PALETTE_STAIN := {
	"#": Color("#7b1f3b"),
	"=": Color("#4a0e25"),
}

const PALETTE_SWARM := {
	"#": Color("#ffeb3b"),  # amarelo ASCII
	"=": Color("#fbc02d"),
}

const PALETTE_ECHO := {
	"#": Color("#00bcd4"),  # cyan glitch
	"=": Color("#0097a7"),
	"o": Color("#e040fb"),  # magenta highlights
	"O": Color("#311b92"),
	"-": Color("#006064"),
}

const PALETTE_CHECKSUM := {
	"#": Color("#ff6f00"),  # laranja
	"=": Color("#bf360c"),  # escuro
	"o": Color("#ffd180"),  # destaque
}

const PALETTE_LEAK := {
	"#": Color("#9c27b0"),  # roxo
	"=": Color("#4a148c"),  # roxo escuro
	"o": Color("#e1bee7"),  # rosa claro
}

const PALETTE_BOSS := {
	"#": Color("#1a0000"),  # preto-vermelho escuro
	"=": Color("#3a0010"),  # body
	"o": Color("#ff0080"),  # eye glow
	"O": Color("#000000"),  # eye core
	"-": Color("#7a0030"),  # detail
	"X": Color("#ffeb3b"),  # warning yellow
}

const PALETTE_BOSS_PROJECTILE := {
	"#": Color("#ff0080"),
	"=": Color("#7a0030"),
}

# --- Inimigos Era 16-bit ---
const PALETTE_HUE_SHIFT := {
	"#": Color("#ffffff"),
	"=": Color("#cccccc"),
	"o": Color("#888888"),
	"O": Color("#333333"),
}

const PALETTE_COMPRESSION := {
	"#": Color("#ff9800"),
	"=": Color("#bf360c"),
	"o": Color("#ffcc80"),
}

const PALETTE_SPRITE_LIMIT := {
	"#": Color("#2196f3"),
	"=": Color("#0d47a1"),
	"o": Color("#e3f2fd"),
	"O": Color("#1565c0"),
}

const PALETTE_BIT_FLIP_ON := {
	"#": Color("#76ff03"),
	"=": Color("#33691e"),
	"o": Color("#f1f8e9"),
	"O": Color("#1b5e20"),
}

const PALETTE_BIT_FLIP_OFF := {
	"#": Color("#424242"),
	"=": Color("#212121"),
	"o": Color("#9e9e9e"),
	"O": Color("#000000"),
}

const PALETTE_FRAGMENTATION := {
	"#": Color("#311b92"),
	"=": Color("#5e35b1"),
	"o": Color("#e040fb"),
	"O": Color("#000000"),
	"-": Color("#1a237e"),
	"X": Color("#ff5252"),
}

# --- Frames (ASCII art) ---
# GAMO Tier 1 (12x18) — robô mascote base, sem armadura.
# Cabeça com visor expressivo (2 olhos), corpo com núcleo de energia laranja,
# braços e pernas claramente separados.
const GAMO_T1_IDLE: Array = [
	[
		"....####....",
		"...######...",
		"..########..",
		"..#OO==OO#..",
		"..#oo==oo#..",
		"..########..",
		"...######...",
		".##======##.",
		"##========##",
		"##==xxxx==##",
		"##========##",
		"##========##",
		".##======##.",
		"...######...",
		"...##..##...",
		"...##..##...",
		"...##..##...",
		"...==..==...",
	],
	[
		"....####....",
		"...######...",
		"..########..",
		"..#oo==oo#..",
		"..#OO==OO#..",
		"..########..",
		"...######...",
		".##======##.",
		"##========##",
		"##==oooo==##",
		"##========##",
		"##========##",
		".##======##.",
		"...######...",
		"...##..##...",
		"...##..##...",
		"...##..##...",
		"...==..==...",
	],
]

# GAMO Tier 2 (14x20) — armadura leve. Ombreiras altas, peito com placa azul-claro
# e núcleo de energia ampliado. Pernas mais robustas.
const GAMO_T2_IDLE: Array = [
	[
		".....####.....",
		"....######....",
		"...########...",
		"...#OO==OO#...",
		"...#oo==oo#...",
		"...########...",
		"....######....",
		".LL########LL.",
		".##L======L##.",
		".##L=xxxx=L##.",
		".##L======L##.",
		".##L======L##.",
		".LL########LL.",
		"....######....",
		"....##..##....",
		"....##..##....",
		"....##..##....",
		"....##..##....",
		"....##..##....",
		"....==..==....",
	],
	[
		".....####.....",
		"....######....",
		"...########...",
		"...#oo==oo#...",
		"...#OO==OO#...",
		"...########...",
		"....######....",
		".LL########LL.",
		".##L======L##.",
		".##L=oooo=L##.",
		".##L======L##.",
		".##L======L##.",
		".LL########LL.",
		"....######....",
		"....##..##....",
		"....##..##....",
		"....##..##....",
		"....##..##....",
		"....##..##....",
		"....==..==....",
	],
]

# GAMO Tier 3 (18x22) — armadura pesada com crown helmet, peito blindado,
# braços externos reforçados e pernas com proteção.
const GAMO_T3_IDLE: Array = [
	[
		".......####.......",
		"......######......",
		"....##########....",
		"....LLLLLLLLLL....",
		"...############...",
		"..##############..",
		"..##L========L##..",
		"..##L=OOooOO=L##..",
		"..##L========L##..",
		"...############...",
		"....##########....",
		".LL############LL.",
		"##L##========##L##",
		"##L############L##",
		"##L##=xxxxxx=##L##",
		"##L############L##",
		"##L##========##L##",
		".LL############LL.",
		"....##########....",
		"....###....###....",
		"....###....###....",
		"....===....===....",
	],
	[
		".......####.......",
		"......######......",
		"....##########....",
		"....LLLLLLLLLL....",
		"...############...",
		"..##############..",
		"..##L========L##..",
		"..##L=ooOOoo=L##..",
		"..##L========L##..",
		"...############...",
		"....##########....",
		".LL############LL.",
		"##L##========##L##",
		"##L############L##",
		"##L##=oooooo=##L##",
		"##L############L##",
		"##L##========##L##",
		".LL############LL.",
		"....##########....",
		"....###....###....",
		"....###....###....",
		"....===....===....",
	],
]

# Armas (1 frame cada) — orientação padrão: cano apontando pra DIREITA (+X)
# A arma é rotacionada por código para mirar no inimigo mais próximo.

# Blaster básico (Star Blaster) 8x4
const WEAPON_BLASTER: Array = [
	[
		".##.....",
		".######o",
		".######o",
		".##.....",
	],
]

# Spread (Spread Cart / Stereo Sound) 8x6 — barril mais largo
const WEAPON_SPREAD: Array = [
	[
		".##.....",
		".######o",
		".#######",
		".#######",
		".######o",
		".##.....",
	],
]

# Mega laser (Mega Blaster / Sonic Boom / Region Free) 10x5
const WEAPON_MEGA: Array = [
	[
		".##.......",
		".#######xo",
		".########o",
		".#######xo",
		".##.......",
	],
]

# Orbital (Pixel Aura / Mode 7 / Vortex / Chaos) 6x6 — dispositivo circular pulsante
const WEAPON_ORBITAL: Array = [
	[
		"..==..",
		".=oo=.",
		"==oo==",
		"==oo==",
		".=oo=.",
		"..==..",
	],
]

# Player (8x10) — cartucho 8-bit "Pixel" (mantido para o inimigo Echo, que copia este sprite)
const PIXEL_IDLE: Array = [
	[
		"  ====  ",
		" =####= ",
		" =#oo#= ",
		" =#oo#= ",
		" =####= ",
		" =-##-= ",
		" =----= ",
		" =====  ",
		" =    = ",
		" =    = ",
	],
	[
		"  ====  ",
		" =####= ",
		" =#oo#= ",
		" =#OO#= ",
		" =####= ",
		" =-##-= ",
		" =----= ",
		" =====  ",
		" =    = ",
		" =    = ",
	],
]

# Slate (12x10) — console portátil chunky tipo Game Gear
const SLATE_IDLE: Array = [
	[
		".##########.",
		"############",
		"#==========#",
		"#=oOoOoOoO=#",
		"#=OoOoOoOo=#",
		"#==========#",
		"##-##==##-##",
		"##========##",
		"##========##",
		".##########.",
	],
	[
		".##########.",
		"############",
		"#==========#",
		"#=oOOOoooO=#",
		"#=OoooOOOo=#",
		"#==========#",
		"##-##==##-##",
		"##========##",
		"##========##",
		".##########.",
	],
]

# Disc (10x10) — disco CD-style
const DISC_IDLE: Array = [
	[
		"...####...",
		".########.",
		".########.",
		"##======##",
		"##=oOoo=##",
		"##=oOoO=##",
		"##======##",
		".########.",
		".########.",
		"...####...",
	],
	[
		"...####...",
		".########.",
		".#OoOoOoO#",
		"##oOoOoO##",
		"##======##",
		"##======##",
		"##OoOoOo##",
		".#oOoOoOo#",
		".########.",
		"...####...",
	],
]

# Handheld (8x12) — portátil slim vertical
const HANDHELD_IDLE: Array = [
	[
		".######.",
		"########",
		"##====##",
		"##=oo=##",
		"##=oO=##",
		"##=oo=##",
		"##====##",
		"########",
		"##====##",
		"##=--=##",
		"##----##",
		".######.",
	],
	[
		".######.",
		"########",
		"##====##",
		"##=oo=##",
		"##=Oo=##",
		"##=oo=##",
		"##====##",
		"########",
		"##====##",
		"##--==##",
		"##----##",
		".######.",
	],
]

# Artifact (6x6) — pixel verde piscando
const ARTIFACT_IDLE: Array = [
	[
		" #### ",
		"#=##=#",
		"######",
		"######",
		"#=##=#",
		" #### ",
	],
	[
		" .... ",
		".####.",
		".####.",
		".####.",
		".####.",
		" .... ",
	],
]

# Tear (12x4) — linha horizontal que se desloca
const TEAR_IDLE: Array = [
	[
		"############",
		"=##=#=##=#==",
		"############",
		"= == ==  ===",
	],
	[
		"=##=#=##=#==",
		"############",
		"= == ==  ===",
		"############",
	],
]

# Null Sprite (8x8) — quadrado missing-texture
const NULL_IDLE: Array = [
	[
		"########",
		"####====",
		"####====",
		"####====",
		"====####",
		"====####",
		"====####",
		"########",
	],
	[
		"====####",
		"====####",
		"====####",
		"========",
		"========",
		"####====",
		"####====",
		"####====",
	],
]

# Projectile (4x4)
const PROJECTILE: Array = [
	[
		" ## ",
		"####",
		"####",
		" ## ",
	],
]

# Bleed (10x10) — blob com gota
const BLEED_IDLE: Array = [
	[
		"..######..",
		".########.",
		"##======##",
		"##=oooo=##",
		"##======##",
		".########.",
		"..######..",
		"...####...",
		"....##....",
		"....##....",
	],
	[
		"..######..",
		".########.",
		"##======##",
		"##=oooo=##",
		"##======##",
		".########.",
		"..######..",
		"...####...",
		"...####...",
		"....##....",
	],
]

# Stain (8x8) — pegada de dano deixada pelo Bleed
const STAIN_IDLE: Array = [
	[
		"..####..",
		".######.",
		"##====##",
		"##====##",
		"##====##",
		"##====##",
		".######.",
		"..####..",
	],
]

# ASCII Swarm (6x6) — caracter glyph
const SWARM_IDLE: Array = [
	[
		"..##..",
		".####.",
		"##==##",
		"##==##",
		".####.",
		"..##..",
	],
	[
		".####.",
		"####..",
		"##====",
		"##==##",
		".####.",
		"..##..",
	],
	[
		"##..##",
		".####.",
		"..##..",
		"..##..",
		".####.",
		"##..##",
	],
]

# Echo (8x10) — cópia distorcida do player
const ECHO_IDLE: Array = [
	[
		"  ====  ",
		" =####= ",
		" =#oo#= ",
		" =#OO#= ",
		" =####= ",
		" =-##-= ",
		" =----= ",
		" =====  ",
		" =    = ",
		" =    = ",
	],
	[
		"  -==-  ",
		" -####- ",
		" -#Oo#- ",
		" -#oO#- ",
		" -####- ",
		" -=##=- ",
		" -====- ",
		" -----  ",
		" -    - ",
		" -    - ",
	],
]

# Checksum (10x10) — hexagonal turret
const CHECKSUM_IDLE: Array = [
	[
		"...####...",
		"..######..",
		".########.",
		"##======##",
		"##=oooo=##",
		"##=oooo=##",
		"##======##",
		".########.",
		"..######..",
		"...####...",
	],
	[
		"...####...",
		"..######..",
		".########.",
		"##======##",
		"##=o##o=##",
		"##=o##o=##",
		"##======##",
		".########.",
		"..######..",
		"...####...",
	],
]

# Memory Leak (10x10) — bloco corrompido
const LEAK_IDLE: Array = [
	[
		"##########",
		"#========#",
		"##=oooo=##",
		"#=o####o=#",
		"#=o####o=#",
		"#=o####o=#",
		"#=o####o=#",
		"##=oooo=##",
		"#========#",
		"##########",
	],
	[
		"##########",
		"#========#",
		"##=oooo=##",
		"#=o#==#o=#",
		"#=o====o=#",
		"#=o====o=#",
		"#=o#==#o=#",
		"##=oooo=##",
		"#========#",
		"##########",
	],
]

# Boss Corruption v1.0 (18x20)
const BOSS_IDLE: Array = [
	[
		"....##########....",
		"...############...",
		"..##############..",
		".################.",
		"##==============##",
		"##=oOoo==ooOo===##",
		"##=oOoo==ooOo===##",
		"##=oOoo==ooOo===##",
		"##==============##",
		"##==----==----==##",
		"##==============##",
		".################.",
		".################.",
		".################.",
		".################.",
		".####XX####XX####.",
		".################.",
		".################.",
		"....##########....",
		"....##########....",
	],
	[
		"....##########....",
		"...############...",
		"..##############..",
		".################.",
		"##==============##",
		"##=Oooo==ooOo===##",
		"##=Oooo==ooOo===##",
		"##=Oooo==ooOo===##",
		"##==============##",
		"##==----==----==##",
		"##==============##",
		".################.",
		".################.",
		".################.",
		".################.",
		".####XX####XX####.",
		".################.",
		".################.",
		"....##########....",
		"....##########....",
	],
]

# HueShift (8x8) — pixel que cicla cores via modulate
const HUE_SHIFT_IDLE: Array = [
	[
		".######.",
		"########",
		"#=oOoo=#",
		"#=oOoo=#",
		"#=oOoo=#",
		"#=oOoo=#",
		"########",
		".######.",
	],
]

# Compression (10x10) — bloco JPG artifact
const COMPRESSION_IDLE: Array = [
	[
		"##========",
		"##========",
		"####======",
		"####=ooo==",
		"=======o==",
		"======####",
		"==o=######",
		"====######",
		"========##",
		"========##",
	],
	[
		"========##",
		"========##",
		"======####",
		"==o===####",
		"=======o==",
		"####======",
		"####=ooo==",
		"####======",
		"##========",
		"##========",
	],
]

# Sprite Limit (10x10) — entidade pixelada que se divide
const SPRITE_LIMIT_IDLE: Array = [
	[
		".########.",
		"#oOoOoOoO#",
		"#OoOoOoOo#",
		"#oOoOoOoO#",
		"#OoOoO=oO#",
		"#oO=oOoOo#",
		"#OoOoOoOo#",
		"#oOoOoOoO#",
		"#OoOoOoOo#",
		".########.",
	],
]

# Bit Flip (8x8) - dois frames pra estados ON/OFF
const BIT_FLIP_IDLE: Array = [
	[
		"########",
		"#======#",
		"#=####=#",
		"#=#oo#=#",
		"#=#oo#=#",
		"#=####=#",
		"#======#",
		"########",
	],
	[
		"########",
		"#oOoOoO#",
		"#OoOoOo#",
		"#oOoOoO#",
		"#OoOoOo#",
		"#oOoOoO#",
		"#OoOoOo#",
		"########",
	],
]

# Boss Fragmentation (20x20) — cubo cristalino corrompido
const FRAGMENTATION_IDLE: Array = [
	[
		".....##########.....",
		"....############....",
		"...####======####...",
		"..####========####..",
		".####==========####.",
		"####=oo==oo===o====#",
		"####=oo==oo===o====#",
		"####==========oo===#",
		"####===XX====oo====#",
		"####===XX==========#",
		"####===========XX==#",
		"####===oo======XX==#",
		"####===oo==========#",
		"#####=============##",
		"##############==####",
		".####------====####.",
		"..####========####..",
		"...####======####...",
		"....############....",
		".....##########.....",
	],
]

# Fragment (10x10) — pedaço do boss após split
const FRAGMENTATION_FRAGMENT: Array = [
	[
		"..######..",
		".########.",
		"########=#",
		"#=######==",
		"#==oo===oo",
		"#==oo===oo",
		"#=######==",
		"########=#",
		".########.",
		"..######..",
	],
]

# Boss projectile (6x6)
const BOSS_PROJECTILE: Array = [
	[
		"..##..",
		".####.",
		"##==##",
		"##==##",
		".####.",
		"..##..",
	],
]

# Health Pickup (7x6) — coração vermelho
const HEALTH_PICKUP: Array = [
	[
		".##.##.",
		"#######",
		"#######",
		".#####.",
		"..###..",
		"...#...",
	],
]

const PALETTE_HEALTH := {
	"#": Color("#e53935"),
	"=": Color("#b71c1c"),
	"o": Color("#ffcdd2"),
}

# Power-ups (8x8 cada). Ícones distintos com paleta vibrante pra "raro/épico".
const POWERUP_FREEZE: Array = [
	[
		"...##...",
		".##oo##.",
		"..####..",
		"##oooo##",
		"##oooo##",
		"..####..",
		".##oo##.",
		"...##...",
	],
]

const POWERUP_NUKE: Array = [
	[
		"..####..",
		".######.",
		"########",
		"##oxxo##",
		"##xooX##",
		"########",
		".######.",
		"..####..",
	],
]

const POWERUP_MAGNET: Array = [
	[
		"##....##",
		"##oo..##",
		"##oo..##",
		"##oo..##",
		"##oo..##",
		"########",
		"########",
		".######.",
	],
]

const PALETTE_FREEZE := {
	"#": Color("#00b0ff"),
	"o": Color("#e1f5fe"),
	"=": Color("#0277bd"),
}

const PALETTE_NUKE := {
	"#": Color("#ff5252"),
	"o": Color("#ffeb3b"),
	"x": Color("#ff9800"),
	"X": Color("#ffffff"),
}

const PALETTE_MAGNET := {
	"#": Color("#e040fb"),
	"o": Color("#f3e5f5"),
	"=": Color("#6a1b9a"),
}

# Mini-boss "Sentinel" (12x12) — corpo robusto com olho central piscante
const MINIBOSS_IDLE: Array = [
	[
		"...####...",
		"..######..",
		".########.",
		"##########",
		"##oOooOo##",
		"##oOooOo##",
		"##========",
		"##========",
		".########.",
		"..######..",
		"...####...",
		"....##....",
	],
	[
		"...####...",
		"..######..",
		".########.",
		"##########",
		"##oOOOOo##",
		"##oOOOOo##",
		"##========",
		"##========",
		".########.",
		"..######..",
		"...####...",
		"....##....",
	],
]

const PALETTE_MINIBOSS := {
	"#": Color("#7b1fa2"),
	"=": Color("#4a148c"),
	"o": Color("#ff5252"),
	"O": Color("#ffeb3b"),
}

# XP Gem (5x5)
const XP_GEM: Array = [
	[
		"..#..",
		".###.",
		"#####",
		".###.",
		"..#..",
	],
	[
		"..=..",
		".###.",
		"##=##",
		".###.",
		"..=..",
	],
]

# --- Cache de texturas geradas ---
var pixel_idle: Array[ImageTexture] = []
var artifact_idle: Array[ImageTexture] = []
var tear_idle: Array[ImageTexture] = []
var null_idle: Array[ImageTexture] = []
var projectile: ImageTexture
var boss_projectile: ImageTexture
var stain: ImageTexture
var xp_gem: Array[ImageTexture] = []
var health_pickup: ImageTexture
var powerup_freeze: ImageTexture
var powerup_nuke: ImageTexture
var powerup_magnet: ImageTexture
var miniboss_idle: Array[ImageTexture] = []

# Armas (texturas únicas, rotacionadas em runtime)
var weapon_blaster: ImageTexture
var weapon_spread: ImageTexture
var weapon_mega: ImageTexture
var weapon_orbital: ImageTexture


func _ready() -> void:
	pixel_idle = _bake_frames(PIXEL_IDLE, PALETTE_PIXEL)
	artifact_idle = _bake_frames(ARTIFACT_IDLE, PALETTE_ARTIFACT)
	tear_idle = _bake_frames(TEAR_IDLE, PALETTE_TEAR)
	null_idle = _bake_frames(NULL_IDLE, PALETTE_NULL)
	projectile = PixelArt.make_sprite(PackedStringArray(PROJECTILE[0]), PALETTE_PROJECTILE)
	boss_projectile = PixelArt.make_sprite(PackedStringArray(BOSS_PROJECTILE[0]), PALETTE_BOSS_PROJECTILE)
	stain = PixelArt.make_sprite(PackedStringArray(STAIN_IDLE[0]), PALETTE_STAIN)
	xp_gem = _bake_frames(XP_GEM, PALETTE_GEM)
	health_pickup = PixelArt.make_sprite(PackedStringArray(HEALTH_PICKUP[0]), PALETTE_HEALTH)
	powerup_freeze = PixelArt.make_sprite(PackedStringArray(POWERUP_FREEZE[0]), PALETTE_FREEZE)
	powerup_nuke = PixelArt.make_sprite(PackedStringArray(POWERUP_NUKE[0]), PALETTE_NUKE)
	powerup_magnet = PixelArt.make_sprite(PackedStringArray(POWERUP_MAGNET[0]), PALETTE_MAGNET)
	miniboss_idle = _bake_frames(MINIBOSS_IDLE, PALETTE_MINIBOSS)
	weapon_blaster = PixelArt.make_sprite(PackedStringArray(WEAPON_BLASTER[0]), PALETTE_WEAPON)
	weapon_spread = PixelArt.make_sprite(PackedStringArray(WEAPON_SPREAD[0]), PALETTE_WEAPON)
	weapon_mega = PixelArt.make_sprite(PackedStringArray(WEAPON_MEGA[0]), PALETTE_WEAPON)
	weapon_orbital = PixelArt.make_sprite(PackedStringArray(WEAPON_ORBITAL[0]), PALETTE_WEAPON)


## Cria um SpriteFrames a partir de frames + paleta (útil pra AnimatedSprite2D).
func make_animation(frames: Array, palette: Dictionary, fps: float = 6.0) -> SpriteFrames:
	return PixelArt.make_animation(frames, palette, fps)


func _bake_frames(frames: Array, palette: Dictionary) -> Array[ImageTexture]:
	var out: Array[ImageTexture] = []
	for frame_data in frames:
		var packed := PackedStringArray(frame_data)
		out.append(PixelArt.make_sprite(packed, palette))
	return out
