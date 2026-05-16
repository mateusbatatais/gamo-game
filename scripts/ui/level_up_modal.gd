## Modal de escolha de cartucho ao subir de nível.
## Pausa o jogo, mostra 3 cartas, e equipa o escolhido.
class_name LevelUpModal
extends CanvasLayer

const CARD_W := 160.0
const CARD_H := 200.0
const CARD_GAP := 12.0

var _card_ids: Array[String] = []
var _buttons: Array[Button] = []
var _root: Control
var _hbox: HBoxContainer
var _focused_index: int = 0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	# CenterContainer ocupa todo o viewport e centraliza seu filho automaticamente.
	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	center.add_child(vbox)

	var title := Label.new()
	title.text = I18n.t("lvl_up_title")
	title.add_theme_color_override("font_color", Color("#ffeb3b"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = I18n.t("lvl_up_subtitle")
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	vbox.add_child(subtitle)

	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", int(CARD_GAP))
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_hbox)


func show_choices(cartridge_ids: Array[String], player_cartridges: Dictionary) -> void:
	_card_ids = cartridge_ids
	for child in _hbox.get_children():
		child.queue_free()
	_buttons.clear()
	_focused_index = 0

	for id in cartridge_ids:
		var btn := _make_card(id, player_cartridges)
		_hbox.add_child(btn)
		_buttons.append(btn)

	# Encadeia focus_neighbor explícitamente — Godot às vezes não detecta auto
	# em HBoxContainer com process_mode = ALWAYS durante pause.
	for i in _buttons.size():
		var left_idx: int = (i - 1 + _buttons.size()) % _buttons.size()
		var right_idx: int = (i + 1) % _buttons.size()
		_buttons[i].focus_neighbor_left = _buttons[left_idx].get_path()
		_buttons[i].focus_neighbor_right = _buttons[right_idx].get_path()

	get_tree().paused = true
	visible = true
	if _buttons.size() > 0:
		_set_focus_to(0)


func _set_focus_to(idx: int) -> void:
	if _buttons.is_empty():
		return
	_focused_index = clampi(idx, 0, _buttons.size() - 1)
	for i in _buttons.size():
		_buttons[i].scale = Vector2.ONE
	_buttons[_focused_index].grab_focus()
	# Pulse visual: leve scale-up no card focado pra deixar mais óbvio
	_buttons[_focused_index].pivot_offset = _buttons[_focused_index].size * 0.5
	_buttons[_focused_index].scale = Vector2(1.08, 1.08)


func _make_card(cartridge_id: String, player_cartridges: Dictionary) -> Button:
	var def: CartridgeRegistry.CartridgeDef = CartridgeRegistry.get_def(cartridge_id)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CARD_W, CARD_H)
	btn.toggle_mode = false
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(_on_card_pressed.bind(cartridge_id))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.12, 1.0)
	sb.border_color = CartridgeRegistry.rarity_color(def.rarity)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	sb_focus.set_border_width_all(5)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	btn.add_child(vbox)

	var name_label := Label.new()
	name_label.text = def.display_name
	name_label.add_theme_color_override("font_color", CartridgeRegistry.rarity_color(def.rarity))
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var type_label := Label.new()
	type_label.text = (
		I18n.t("lvl_up_weapon") if def.type == CartridgeRegistry.CartridgeType.WEAPON
		else I18n.t("lvl_up_passive")
	)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_label)

	var current_level: int = player_cartridges.get(cartridge_id, 0)
	var status: String
	if current_level == 0:
		status = I18n.t("lvl_up_new")
	else:
		status = I18n.tf("lvl_up_level", [current_level, current_level + 1])
	var status_label := Label.new()
	status_label.text = status
	status_label.add_theme_color_override("font_color", Color("#9bbc0f"))
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

	var desc := Label.new()
	desc.text = def.description
	desc.add_theme_color_override("font_color", Color.WHITE)
	desc.add_theme_font_size_override("font_size", 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	return btn


func _on_card_pressed(cartridge_id: String) -> void:
	hide()
	get_tree().paused = false
	EventBus.level_up_choice_made.emit(cartridge_id)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	var ev := event as InputEventKey
	if not ev.pressed or ev.echo:
		return
	var k: int = ev.keycode

	# Navegação por setas / A-D (espelha o move_left/right do gameplay)
	match k:
		KEY_LEFT, KEY_A:
			_set_focus_to((_focused_index - 1 + _buttons.size()) % _buttons.size())
			get_viewport().set_input_as_handled()
			return
		KEY_RIGHT, KEY_D:
			_set_focus_to((_focused_index + 1) % _buttons.size())
			get_viewport().set_input_as_handled()
			return
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if _focused_index >= 0 and _focused_index < _card_ids.size():
				# Emite pressed pra que TODOS os handlers conectados rodem
				# (incluindo o auto-hook do Audio.UI_CONFIRM).
				_buttons[_focused_index].pressed.emit()
				get_viewport().set_input_as_handled()
			return

	# Atalhos 1/2/3
	var idx := -1
	match k:
		KEY_1:
			idx = 0
		KEY_2:
			idx = 1
		KEY_3:
			idx = 2
	if idx >= 0 and idx < _card_ids.size() and idx < _buttons.size():
		_buttons[idx].pressed.emit()
		get_viewport().set_input_as_handled()
