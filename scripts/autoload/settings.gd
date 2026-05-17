## Configurações do jogador (volume, shader CRT, fullscreen, etc).
## Persistidas em user://settings.cfg.
extends Node

const SETTINGS_PATH := "user://settings.cfg"

# --- Áudio ---
var master_volume: float = 0.8  # 0.0-1.0
var sfx_volume: float = 0.8

# --- Vídeo ---
var fullscreen: bool = false
var crt_shader_enabled: bool = true
var screen_shake: bool = true

# --- Acessibilidade ---
var photosensitive_mode: bool = false  # reduz flashes e shake
var colorblind_mode: bool = false  # ajusta cores críticas (HP, dano) pra evitar confusão

# --- Localização ---
var locale: String = "pt_BR"

# --- Controles customizados ---
## key = action name (move_up, etc), value = Dict com tipo/code do evento
var custom_keybinds: Dictionary = {}

signal changed


func _ready() -> void:
	load_settings()
	apply_all()


func apply_all() -> void:
	_apply_audio()
	_apply_fullscreen()
	apply_keybinds_from_save()
	I18n.set_locale(locale)
	changed.emit()


func _apply_audio() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(master_volume, 0.001, 1.0)))


func _apply_fullscreen() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_audio()
	save_settings()
	changed.emit()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	save_settings()
	changed.emit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()
	save_settings()
	changed.emit()


func set_crt_enabled(value: bool) -> void:
	crt_shader_enabled = value
	save_settings()
	changed.emit()


func set_screen_shake(value: bool) -> void:
	screen_shake = value
	save_settings()
	changed.emit()


func set_photosensitive(value: bool) -> void:
	photosensitive_mode = value
	save_settings()
	changed.emit()


func set_colorblind(value: bool) -> void:
	colorblind_mode = value
	save_settings()
	changed.emit()


func set_locale(new_locale: String) -> void:
	locale = new_locale
	I18n.set_locale(new_locale)
	save_settings()
	changed.emit()


func set_keybind(action: String, event: InputEvent) -> void:
	custom_keybinds[action] = _serialize_event(event)
	_apply_keybind(action, event)
	save_settings()
	changed.emit()


func reset_keybinds() -> void:
	custom_keybinds.clear()
	save_settings()
	# Notar: pra restaurar defaults sem reset do projeto, basta não aplicar nada
	# e o InputMap volta ao definido em project.godot na próxima inicialização


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "keycode": (event as InputEventKey).physical_keycode}
	if event is InputEventJoypadButton:
		return {"type": "joybutton", "button_index": (event as InputEventJoypadButton).button_index}
	return {}


func _deserialize_event(data: Dictionary) -> InputEvent:
	match data.get("type", ""):
		"key":
			var e := InputEventKey.new()
			e.physical_keycode = data.get("keycode", 0)
			return e
		"joybutton":
			var e := InputEventJoypadButton.new()
			e.button_index = data.get("button_index", 0)
			return e
	return null


func _apply_keybind(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	# Remove apenas events do mesmo tipo (preserva outros bindings)
	for existing in InputMap.action_get_events(action).duplicate():
		if (event is InputEventKey and existing is InputEventKey) or \
		   (event is InputEventJoypadButton and existing is InputEventJoypadButton):
			InputMap.action_erase_event(action, existing)
	InputMap.action_add_event(action, event)


func apply_keybinds_from_save() -> void:
	for action in custom_keybinds.keys():
		var event := _deserialize_event(custom_keybinds[action])
		if event != null:
			_apply_keybind(action, event)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "crt", crt_shader_enabled)
	cfg.set_value("video", "screen_shake", screen_shake)
	cfg.set_value("a11y", "photosensitive", photosensitive_mode)
	cfg.set_value("a11y", "colorblind", colorblind_mode)
	cfg.set_value("locale", "current", locale)
	cfg.set_value("controls", "keybinds", custom_keybinds)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master", master_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	crt_shader_enabled = cfg.get_value("video", "crt", crt_shader_enabled)
	screen_shake = cfg.get_value("video", "screen_shake", screen_shake)
	photosensitive_mode = cfg.get_value("a11y", "photosensitive", photosensitive_mode)
	colorblind_mode = cfg.get_value("a11y", "colorblind", colorblind_mode)
	locale = cfg.get_value("locale", "current", locale)
	var raw_keybinds: Dictionary = cfg.get_value("controls", "keybinds", {})
	custom_keybinds = raw_keybinds
