## CRT overlay global. CanvasLayer no topo que aplica shader CRT.
## Toggle via Settings.crt_shader_enabled.
extends CanvasLayer

const SHADER_PATH := "res://shaders/crt.gdshader"

var _color_rect: ColorRect
var _shader_material: ShaderMaterial


func _ready() -> void:
	layer = 100  # acima de tudo
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	Settings.changed.connect(_on_settings_changed)
	_apply_settings()


func _build() -> void:
	_color_rect = ColorRect.new()
	_color_rect.anchor_right = 1.0
	_color_rect.anchor_bottom = 1.0
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader: Shader = load(SHADER_PATH)
	if shader != null:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		_color_rect.material = _shader_material
	add_child(_color_rect)


func _on_settings_changed() -> void:
	_apply_settings()


func _apply_settings() -> void:
	if _color_rect == null:
		return
	_color_rect.visible = Settings.crt_shader_enabled
