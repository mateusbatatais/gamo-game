## Utilitário pra gerar StyleBoxes "chunky" estilo SNES — borda dupla (clara
## por fora + escura por dentro), com ornamentos de canto pixelados que dão
## sensação de placa de cartucho/console.
class_name PanelFrames
extends RefCounted


## StyleBox principal com borda dupla pixelada. Use em Panels do HUD.
## - bg: cor de fundo
## - outer: cor da borda externa (geralmente clara, tipo metal/cromo)
## - inner: cor da borda interna (escura, contraste)
static func chunky(bg: Color, outer: Color, inner: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = outer
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)  # 16-bit não tem cantos arredondados
	# "Borda interna" simulada via shadow de offset zero
	sb.shadow_color = inner
	sb.shadow_size = 1
	sb.shadow_offset = Vector2.ZERO
	# Pequeno expand pra borda dupla aparecer
	sb.expand_margin_top = 1
	sb.expand_margin_bottom = 1
	sb.expand_margin_left = 1
	sb.expand_margin_right = 1
	return sb


## Frame "destaque" — usado quando o painel tá selecionado/ativo.
static func chunky_highlight(bg: Color, accent: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(0)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 0
	return sb


## Cria uma textura procedural pra simular ornamento de canto pixelado.
## É um sprite 6x6 com cantos chanfrados (formato L invertido tipo SNES).
static func corner_ornament(color: Color) -> ImageTexture:
	var img := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Padrão L invertido no canto superior-esquerdo (pode ser rotacionado).
	for x in 6:
		img.set_pixel(x, 0, color)
		img.set_pixel(0, x, color)
	img.set_pixel(2, 1, color)
	img.set_pixel(1, 2, color)
	return ImageTexture.create_from_image(img)


## Cria uma barra "preenchimento" pixelada com gradiente vertical sutil.
## Útil pra HP/XP. width muda em runtime; height é fixo.
static func bar_fill(color: Color, height: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = color.lightened(0.35)
	sb.border_width_top = 1
	sb.set_corner_radius_all(0)
	return sb
