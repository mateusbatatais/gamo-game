## Menu de pause acionado pelo ESC durante o gameplay.
## Pausa o tree e oferece Continuar / Menu Principal / Sair.
class_name PauseMenu
extends CanvasLayer

signal resume_requested

var _root: Control
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.78)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	var title := Label.new()
	title.text = I18n.t("pause_title")
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#ffeb3b"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_buttons.clear()
	var resume_btn := _make_button(I18n.t("pause_resume"), true)
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)
	_buttons.append(resume_btn)

	var menu_btn := _make_button(I18n.t("pause_menu"), false)
	menu_btn.pressed.connect(_on_main_menu)
	vbox.add_child(menu_btn)
	_buttons.append(menu_btn)

	var quit_btn := _make_button(I18n.t("pause_quit"), false)
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)
	_buttons.append(quit_btn)


func _make_button(text: String, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 32)
	btn.add_theme_font_size_override("font_size", 18)
	btn.focus_mode = Control.FOCUS_ALL

	var accent := Color("#9bbc0f") if primary else Color("#bdbdbd")
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.14, 1.0)
	sb.border_color = Color("#306230") if primary else Color(0.35, 0.35, 0.35)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color("#1b3b1b") if primary else Color(0.18, 0.18, 0.22)
	sb_focus.border_color = accent
	sb_focus.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", accent)
	return btn


func open() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true
	if _buttons.size() > 0:
		_buttons[0].grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	resume_requested.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _on_resume() -> void:
	close()


func _on_main_menu() -> void:
	get_tree().paused = false
	visible = false
	SceneRouter.go_to_main_menu()


func _on_quit() -> void:
	get_tree().paused = false
	SceneRouter.quit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
