## Tela de opções: áudio, vídeo, acessibilidade, controles, idioma.
extends Control

const VIEWPORT_W := 640
const VIEWPORT_H := 360

const REBIND_ACTIONS: Array[String] = [
	"move_up", "move_down", "move_left", "move_right", "dash"
]

var _rebind_buttons: Dictionary = {}  # action -> Button
var _rebinding_action: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(VIEWPORT_W, VIEWPORT_H)
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a14")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var title := Label.new()
	title.text = I18n.t("options_title")
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#ffeb3b"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.position = Vector2(-70, 8)
	title.size = Vector2(140, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# 2 colunas — esquerda: audio/video/a11y/idioma; direita: controles
	var left_vbox := VBoxContainer.new()
	left_vbox.position = Vector2(20, 48)
	left_vbox.size = Vector2(320, 260)
	left_vbox.add_theme_constant_override("separation", 6)
	add_child(left_vbox)

	left_vbox.add_child(_make_section_label(I18n.t("options_audio")))
	left_vbox.add_child(_make_volume_row(
		I18n.t("options_volume_master"),
		Settings.master_volume,
		func(v: float) -> void: Settings.set_master_volume(v)
	))
	left_vbox.add_child(_make_volume_row(
		I18n.t("options_volume_sfx"),
		Settings.sfx_volume,
		func(v: float) -> void: Settings.set_sfx_volume(v)
	))

	left_vbox.add_child(_make_section_label(I18n.t("options_video")))
	left_vbox.add_child(_make_checkbox_row(
		I18n.t("options_fullscreen"), Settings.fullscreen,
		func(v: bool) -> void: Settings.set_fullscreen(v)
	))
	left_vbox.add_child(_make_checkbox_row(
		I18n.t("options_crt"), Settings.crt_shader_enabled,
		func(v: bool) -> void: Settings.set_crt_enabled(v)
	))
	left_vbox.add_child(_make_checkbox_row(
		I18n.t("options_screen_shake"), Settings.screen_shake,
		func(v: bool) -> void: Settings.set_screen_shake(v)
	))

	left_vbox.add_child(_make_section_label(I18n.t("options_a11y")))
	left_vbox.add_child(_make_checkbox_row(
		I18n.t("options_photosensitive"), Settings.photosensitive_mode,
		func(v: bool) -> void: Settings.set_photosensitive(v)
	))

	left_vbox.add_child(_make_section_label(I18n.t("options_language")))
	left_vbox.add_child(_make_language_row())

	# --- Coluna direita: Controles ---
	var right_vbox := VBoxContainer.new()
	right_vbox.position = Vector2(360, 48)
	right_vbox.size = Vector2(260, 260)
	right_vbox.add_theme_constant_override("separation", 4)
	add_child(right_vbox)

	right_vbox.add_child(_make_section_label(I18n.t("options_controls")))
	for action in REBIND_ACTIONS:
		right_vbox.add_child(_make_rebind_row(action))

	# Botão Voltar
	var back := _make_button(I18n.t("options_back"))
	back.pressed.connect(_on_back)
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.anchor_left = 0.5
	back.anchor_right = 0.5
	back.position = Vector2(-70, -36)
	back.size = Vector2(140, 28)
	add_child(back)
	back.grab_focus()


func _make_section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color("#9bbc0f"))
	return l


func _make_volume_row(label_text: String, value: float, on_change: Callable) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 11)
	label.custom_minimum_size = Vector2(120, 16)
	hbox.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(140, 16)
	slider.value_changed.connect(func(v: float) -> void: on_change.call(v))
	hbox.add_child(slider)

	var pct := Label.new()
	pct.add_theme_font_size_override("font_size", 10)
	pct.text = "%d%%" % int(value * 100.0)
	pct.custom_minimum_size = Vector2(36, 16)
	slider.value_changed.connect(func(v: float) -> void: pct.text = "%d%%" % int(v * 100.0))
	hbox.add_child(pct)

	return hbox


func _make_checkbox_row(label_text: String, value: bool, on_change: Callable) -> Control:
	var hbox := HBoxContainer.new()
	var checkbox := CheckBox.new()
	checkbox.button_pressed = value
	checkbox.text = label_text
	checkbox.add_theme_font_size_override("font_size", 11)
	checkbox.toggled.connect(func(v: bool) -> void: on_change.call(v))
	hbox.add_child(checkbox)
	return hbox


func _make_language_row() -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	for locale in I18n.available_locales():
		var btn := Button.new()
		btn.text = I18n.locale_display_name(locale)
		btn.custom_minimum_size = Vector2(110, 22)
		btn.add_theme_font_size_override("font_size", 11)
		var is_current: bool = locale == Settings.locale
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#1b3b1b") if is_current else Color(0.08, 0.1, 0.14, 1.0)
		sb.border_color = Color("#9bbc0f") if is_current else Color("#306230")
		sb.set_border_width_all(2)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.pressed.connect(func() -> void:
			Settings.set_locale(locale)
			_reload_scene()
		)
		hbox.add_child(btn)

	return hbox


func _make_rebind_row(action: String) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = action.to_upper().replace("_", " ")
	label.add_theme_font_size_override("font_size", 11)
	label.custom_minimum_size = Vector2(100, 22)
	hbox.add_child(label)

	var btn := Button.new()
	btn.text = _action_binding_text(action)
	btn.custom_minimum_size = Vector2(140, 22)
	btn.add_theme_font_size_override("font_size", 11)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.14, 1.0)
	sb.border_color = Color("#306230")
	sb.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.pressed.connect(_on_rebind_pressed.bind(action))
	hbox.add_child(btn)
	_rebind_buttons[action] = btn

	return hbox


func _action_binding_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key: InputEventKey = event
			var label := OS.get_keycode_string(key.physical_keycode)
			if label.is_empty():
				label = OS.get_keycode_string(key.keycode)
			if not label.is_empty():
				return label
		elif event is InputEventJoypadButton:
			return "GAMEPAD %d" % (event as InputEventJoypadButton).button_index
	return "?"


func _on_rebind_pressed(action: String) -> void:
	_rebinding_action = action
	var btn: Button = _rebind_buttons.get(action, null)
	if btn != null:
		btn.text = I18n.t("options_rebind_press")


func _unhandled_input(event: InputEvent) -> void:
	if _rebinding_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		Settings.set_keybind(_rebinding_action, event)
		var btn: Button = _rebind_buttons.get(_rebinding_action, null)
		if btn != null:
			btn.text = _action_binding_text(_rebinding_action)
		_rebinding_action = ""
		get_viewport().set_input_as_handled()


func _reload_scene() -> void:
	SceneRouter.go_to_options()


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 28)
	btn.add_theme_font_size_override("font_size", 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.12, 0.18, 1.0)
	sb.border_color = Color("#306230")
	sb.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color("#306230")
	sb_focus.border_color = Color("#9bbc0f")
	sb_focus.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn


func _on_back() -> void:
	SceneRouter.go_to_main_menu()
