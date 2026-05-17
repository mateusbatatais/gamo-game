## Pixelifica a fonte default do Godot pra dar feel 16-bit em todos os textos:
##   - Antialiasing OFF (sem suavização de bordas)
##   - Hinting OFF
##   - Subpixel positioning DISABLED (cada char alinhado a pixel inteiro)
##
## Como modifica ThemeDB.fallback_font (singleton compartilhado), o efeito
## atinge todos os Labels/Buttons que não tenham font_override próprio.
extends Node


func _ready() -> void:
	var fb := ThemeDB.fallback_font
	if fb == null:
		push_warning("ThemeDB.fallback_font não disponível — pixelify ignorado.")
		return
	# A fallback font geralmente é um FontFile (TrueType). Tentamos cast.
	if fb is FontFile:
		var ff: FontFile = fb
		# Antialiasing GRAYSCALE em vez de NONE — preserva feel chunky em textos
		# grandes mas evita jaggies severas nos labels pequenos (10-12).
		ff.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		ff.hinting = TextServer.HINTING_FULL
		ff.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		ff.force_autohinter = false
		ff.allow_system_fallback = false
	# Tamanhos default sobem pra 13 — labels sem override ficam mais legíveis.
	ThemeDB.fallback_font_size = max(ThemeDB.fallback_font_size, 13)
