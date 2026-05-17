## Strip de boons ativos no HUD — mostra cada boon como um quadradinho colorido
## com barrinha de tempo restante. Escuta EventBus.boons_changed pra atualizar.
class_name BoonStrip
extends Control

const ICON_SIZE := 22
const ICON_GAP := 4

var _icons: Array[Control] = []
var _kinds: Array[int] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.boons_changed.connect(_rebuild)


func _rebuild(active_boons: Array) -> void:
	for icon in _icons:
		icon.queue_free()
	_icons.clear()
	_kinds.clear()
	for boon in active_boons:
		var b: BoonSystem.ActiveBoon = boon
		_kinds.append(b.kind)
		_icons.append(_make_icon(b))
	_layout()


func _make_icon(boon: BoonSystem.ActiveBoon) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	panel.size = Vector2(ICON_SIZE, ICON_SIZE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.85)
	sb.border_color = BoonSystem.COLORS[boon.kind]
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	# Orbe central com a cor do boon
	var orb := ColorRect.new()
	orb.color = BoonSystem.COLORS[boon.kind]
	orb.position = Vector2(5, 4)
	orb.size = Vector2(12, 12)
	panel.add_child(orb)

	# Barra de tempo na base
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.1, 0.1, 0.1, 0.7)
	bar_bg.position = Vector2(2, ICON_SIZE - 4)
	bar_bg.size = Vector2(ICON_SIZE - 4, 2)
	panel.add_child(bar_bg)

	var bar := ColorRect.new()
	bar.color = BoonSystem.COLORS[boon.kind]
	bar.position = Vector2(2, ICON_SIZE - 4)
	bar.size = Vector2(ICON_SIZE - 4, 2)
	bar.set_meta("boon_kind", boon.kind)
	panel.add_child(bar)

	return panel


func _process(_delta: float) -> void:
	# Atualiza tamanho das barras de tempo restante.
	for i in _icons.size():
		var icon := _icons[i] as Panel
		if icon == null:
			continue
		var kind: int = _kinds[i]
		var time_left: float = 0.0
		var duration: float = 1.0
		for b in BoonSystem.active_kinds():
			var bk: BoonSystem.ActiveBoon = b
			if bk.kind == kind:
				time_left = bk.time_left
				duration = bk.duration_total
				break
		var bar_node: ColorRect = icon.get_child(2) as ColorRect  # bar
		if bar_node != null:
			var t: float = clampf(time_left / duration, 0.0, 1.0)
			bar_node.size.x = (ICON_SIZE - 4) * t


func _layout() -> void:
	var x: int = 0
	for icon in _icons:
		icon.position = Vector2(x, 0)
		x += ICON_SIZE + ICON_GAP
