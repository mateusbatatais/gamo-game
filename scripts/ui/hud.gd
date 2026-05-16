## HUD da run: HP, XP, timer, level, cartuchos equipados.
class_name HUD
extends CanvasLayer

const VIEWPORT_W := 640
const VIEWPORT_H := 360
# Marcadores na barra de progresso da fase — espelham os tempos do Arena.
const BOSS_SPAWN_TIME := 360.0
const MINI_BOSS_TIMES := [90.0, 210.0, 330.0]
const STAGE_BAR_WIDTH := 300.0
const STAGE_BAR_HEIGHT := 6.0

var _hp_bar: ColorRect
var _hp_bg: ColorRect
var _hp_label: Label
var _xp_bar: ColorRect
var _xp_bg: ColorRect
var _level_label: Label
var _timer_label: Label
var _kills_label: Label
var _cartridge_box: HBoxContainer

var _boss_bar_bg: ColorRect
var _boss_bar: ColorRect
var _boss_name: Label
var _warning_label: Label
var _warning_timer: float = 0.0

var _combo_label: Label
var _combo_pulse: float = 0.0

var _stage_bar_bg: ColorRect
var _stage_bar_fill: ColorRect
var _stage_bar_root: Control
var _boss_countdown_label: Label
var _stage_label: Label

var _player: Player


func _ready() -> void:
	layer = 5
	_build()
	_build_stage_progress()
	_build_boss_ui()
	_build_warning_label()
	_build_combo_label()
	_build_hp_vignette()
	_connect_signals()


func _build_stage_progress() -> void:
	# Barra horizontal no topo central com marcadores de mini-boss e ícone de boss.
	_stage_bar_root = Control.new()
	_stage_bar_root.anchor_left = 0.5
	_stage_bar_root.anchor_right = 0.5
	_stage_bar_root.position = Vector2(-STAGE_BAR_WIDTH * 0.5, 6)
	_stage_bar_root.size = Vector2(STAGE_BAR_WIDTH, 30)
	_stage_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage_bar_root)

	# Texto pequeno acima
	_stage_label = Label.new()
	_stage_label.text = "FASE 1 — BOSS EM 6:00"
	_stage_label.add_theme_font_size_override("font_size", 10)
	_stage_label.add_theme_color_override("font_color", Color("#bdbdbd"))
	_stage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_stage_label.add_theme_constant_override("outline_size", 2)
	_stage_label.position = Vector2(0, 0)
	_stage_label.size = Vector2(STAGE_BAR_WIDTH, 12)
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_bar_root.add_child(_stage_label)

	# BG da barra com frame chunky
	var stage_frame := Panel.new()
	stage_frame.position = Vector2(-2, 12)
	stage_frame.size = Vector2(STAGE_BAR_WIDTH + 4, STAGE_BAR_HEIGHT + 4)
	var stage_sb := PanelFrames.chunky(
		Color(0.05, 0.05, 0.1, 0.9),
		Color("#3949ab"),
		Color(0, 0, 0, 1)
	)
	stage_frame.add_theme_stylebox_override("panel", stage_sb)
	_stage_bar_root.add_child(stage_frame)

	_stage_bar_bg = ColorRect.new()
	_stage_bar_bg.color = Color(0.02, 0.02, 0.06, 0.0)
	_stage_bar_bg.position = Vector2(0, 14)
	_stage_bar_bg.size = Vector2(STAGE_BAR_WIDTH, STAGE_BAR_HEIGHT)
	_stage_bar_root.add_child(_stage_bar_bg)

	# Preenchimento (cresce com o tempo da run)
	_stage_bar_fill = ColorRect.new()
	_stage_bar_fill.color = Color("#9bbc0f")
	_stage_bar_fill.position = Vector2(0, 14)
	_stage_bar_fill.size = Vector2(0, STAGE_BAR_HEIGHT)
	_stage_bar_root.add_child(_stage_bar_fill)

	# Ticks de mini-boss em cima da barra (pequenos retângulos roxos)
	for mini_time in MINI_BOSS_TIMES:
		var t_norm: float = float(mini_time) / BOSS_SPAWN_TIME
		var tick := ColorRect.new()
		tick.color = Color("#e040fb")
		tick.position = Vector2(STAGE_BAR_WIDTH * t_norm - 1.5, 11)
		tick.size = Vector2(3, STAGE_BAR_HEIGHT + 6)
		_stage_bar_root.add_child(tick)

	# Marker de boss na ponta direita (ícone "B" vermelho)
	var boss_marker := Label.new()
	boss_marker.text = "B"
	boss_marker.add_theme_font_size_override("font_size", 14)
	boss_marker.add_theme_color_override("font_color", Color("#ff5252"))
	boss_marker.add_theme_color_override("font_outline_color", Color.BLACK)
	boss_marker.add_theme_constant_override("outline_size", 3)
	boss_marker.position = Vector2(STAGE_BAR_WIDTH + 2, 10)
	boss_marker.size = Vector2(14, 14)
	_stage_bar_root.add_child(boss_marker)

	# Countdown logo abaixo
	_boss_countdown_label = Label.new()
	_boss_countdown_label.text = ""
	_boss_countdown_label.add_theme_font_size_override("font_size", 10)
	_boss_countdown_label.add_theme_color_override("font_color", Color("#ff5252"))
	_boss_countdown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_boss_countdown_label.add_theme_constant_override("outline_size", 2)
	_boss_countdown_label.position = Vector2(0, 22)
	_boss_countdown_label.size = Vector2(STAGE_BAR_WIDTH, 12)
	_boss_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_bar_root.add_child(_boss_countdown_label)


func _build_hp_vignette() -> void:
	# Renderizado em CanvasLayer separado por baixo do HUD (layer 3) pra não
	# cobrir os textos do HUD com o vermelho.
	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 3
	add_child(vignette_layer)
	var vignette := HpVignette.new()
	vignette_layer.add_child(vignette)


func _build_combo_label() -> void:
	_combo_label = Label.new()
	_combo_label.text = ""
	_combo_label.add_theme_font_size_override("font_size", 22)
	_combo_label.add_theme_color_override("font_color", Color("#ff9800"))
	_combo_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_combo_label.add_theme_constant_override("outline_size", 4)
	_combo_label.anchor_left = 0.5
	_combo_label.anchor_right = 0.5
	_combo_label.anchor_top = 1.0
	_combo_label.position = Vector2(-100, -68)
	_combo_label.size = Vector2(200, 28)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.visible = false
	add_child(_combo_label)


func bind_player(p: Player) -> void:
	_player = p
	_update_hp(p.current_hp, p.max_hp)


func _build() -> void:
	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- HP (top-left) com frame chunky SNES ---
	var hp_frame := Panel.new()
	hp_frame.position = Vector2(6, 6)
	hp_frame.size = Vector2(144, 16)
	var hp_sb := PanelFrames.chunky(
		Color(0.06, 0.0, 0.0, 0.92),
		Color("#c62828"),
		Color(0, 0, 0, 1)
	)
	hp_frame.add_theme_stylebox_override("panel", hp_sb)
	root.add_child(hp_frame)

	# ColorRect mantido por baixo só pra controlar a barra de preenchimento (animada).
	_hp_bg = ColorRect.new()
	_hp_bg.color = Color(0.08, 0.0, 0.0, 0.6)
	_hp_bg.position = Vector2(10, 10)
	_hp_bg.size = Vector2(136, 8)
	root.add_child(_hp_bg)

	_hp_bar = ColorRect.new()
	_hp_bar.color = Color("#e53935")
	_hp_bar.position = Vector2(10, 10)
	_hp_bar.size = Vector2(136, 8)
	root.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.position = Vector2(8, 22)
	_hp_label.add_theme_font_size_override("font_size", 14)
	_hp_label.add_theme_color_override("font_color", Color.WHITE)
	_hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hp_label.add_theme_constant_override("outline_size", 3)
	_hp_label.text = "HP 100/100"
	root.add_child(_hp_label)

	# --- Timer + Level (top-right) ---
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 18)
	_timer_label.add_theme_color_override("font_color", Color("#ffeb3b"))
	_timer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_timer_label.add_theme_constant_override("outline_size", 3)
	_timer_label.text = "0:00"
	_timer_label.anchor_left = 1.0
	_timer_label.anchor_right = 1.0
	_timer_label.position = Vector2(-100, 4)
	_timer_label.size = Vector2(92, 22)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_timer_label)

	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 22)
	_level_label.add_theme_color_override("font_color", Color("#00e5ff"))
	_level_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_level_label.add_theme_constant_override("outline_size", 3)
	_level_label.text = "LV 1"
	_level_label.anchor_left = 1.0
	_level_label.anchor_right = 1.0
	_level_label.position = Vector2(-100, 26)
	_level_label.size = Vector2(92, 26)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_level_label)

	_kills_label = Label.new()
	_kills_label.add_theme_font_size_override("font_size", 12)
	_kills_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_kills_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_kills_label.add_theme_constant_override("outline_size", 3)
	_kills_label.text = "KILLS 0"
	_kills_label.anchor_left = 1.0
	_kills_label.anchor_right = 1.0
	_kills_label.position = Vector2(-100, 54)
	_kills_label.size = Vector2(92, 16)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_kills_label)

	# --- XP bar (bottom strip) ---
	_xp_bg = ColorRect.new()
	_xp_bg.color = Color(0.0, 0.05, 0.1, 0.85)
	_xp_bg.anchor_top = 1.0
	_xp_bg.anchor_bottom = 1.0
	_xp_bg.anchor_right = 1.0
	_xp_bg.offset_top = -12
	_xp_bg.offset_bottom = 0
	_xp_bg.offset_left = 0
	_xp_bg.offset_right = 0
	root.add_child(_xp_bg)

	_xp_bar = ColorRect.new()
	_xp_bar.color = Color("#00e5ff")
	_xp_bar.anchor_top = 1.0
	_xp_bar.anchor_bottom = 1.0
	_xp_bar.offset_top = -10
	_xp_bar.offset_bottom = -2
	_xp_bar.offset_left = 2
	_xp_bar.size = Vector2(0, 8)
	root.add_child(_xp_bar)

	# --- Cartridge slots (above XP bar) ---
	_cartridge_box = HBoxContainer.new()
	_cartridge_box.anchor_top = 1.0
	_cartridge_box.anchor_bottom = 1.0
	_cartridge_box.offset_top = -32
	_cartridge_box.offset_bottom = -16
	_cartridge_box.offset_left = 8
	_cartridge_box.add_theme_constant_override("separation", 4)
	root.add_child(_cartridge_box)


func _build_boss_ui() -> void:
	_boss_name = Label.new()
	_boss_name.text = "CORRUPTION v1.0"
	_boss_name.add_theme_font_size_override("font_size", 14)
	_boss_name.add_theme_color_override("font_color", Color("#ff0080"))
	_boss_name.add_theme_color_override("font_outline_color", Color.BLACK)
	_boss_name.add_theme_constant_override("outline_size", 3)
	_boss_name.anchor_left = 0.5
	_boss_name.anchor_right = 0.5
	_boss_name.position = Vector2(-100, 8)
	_boss_name.size = Vector2(200, 18)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.visible = false
	add_child(_boss_name)

	_boss_bar_bg = ColorRect.new()
	_boss_bar_bg.color = Color(0.15, 0.0, 0.05, 0.9)
	_boss_bar_bg.anchor_left = 0.5
	_boss_bar_bg.anchor_right = 0.5
	_boss_bar_bg.position = Vector2(-160, 26)
	_boss_bar_bg.size = Vector2(320, 10)
	_boss_bar_bg.visible = false
	add_child(_boss_bar_bg)

	_boss_bar = ColorRect.new()
	_boss_bar.color = Color("#ff0080")
	_boss_bar.anchor_left = 0.5
	_boss_bar.anchor_right = 0.5
	_boss_bar.position = Vector2(-158, 28)
	_boss_bar.size = Vector2(316, 6)
	_boss_bar.visible = false
	add_child(_boss_bar)


func _build_warning_label() -> void:
	_warning_label = Label.new()
	_warning_label.text = ""
	_warning_label.add_theme_font_size_override("font_size", 28)
	_warning_label.add_theme_color_override("font_color", Color("#ff0080"))
	_warning_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_warning_label.add_theme_constant_override("outline_size", 4)
	_warning_label.anchor_left = 0.5
	_warning_label.anchor_right = 0.5
	_warning_label.anchor_top = 0.5
	_warning_label.position = Vector2(-200, -20)
	_warning_label.size = Vector2(400, 40)
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.visible = false
	add_child(_warning_label)


func _connect_signals() -> void:
	EventBus.player_damaged.connect(_on_hp_changed)
	EventBus.player_healed.connect(_on_hp_changed)
	EventBus.xp_gained.connect(_on_xp_changed)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.level_up_choice_made.connect(_on_level_up_choice_made)
	EventBus.cartridge_equipped.connect(_on_cartridge_changed)
	EventBus.boss_warning.connect(_on_boss_warning)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_damaged.connect(_on_boss_damaged)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.combo_changed.connect(_on_combo_changed)


func _process(delta: float) -> void:
	_timer_label.text = _format_time(GameState.run_time)
	_kills_label.text = I18n.tf("hud_kills", [GameState.run_kills])
	_update_stage_progress()
	if _warning_timer > 0.0:
		_warning_timer -= delta
		var blink: float = absf(sin(float(Time.get_ticks_msec()) * 0.012))
		_warning_label.modulate.a = 0.4 + 0.6 * blink
		if _warning_timer <= 0.0:
			_warning_label.visible = false
	_update_combo_visual(delta)


func _update_stage_progress() -> void:
	if _stage_bar_fill == null:
		return
	var t: float = clampf(GameState.run_time / BOSS_SPAWN_TIME, 0.0, 1.0)
	_stage_bar_fill.size = Vector2(STAGE_BAR_WIDTH * t, STAGE_BAR_HEIGHT)
	# Cor pulsa pra vermelho quando perto do boss
	if t >= 0.95:
		_stage_bar_fill.color = Color("#ff5252")
	elif t >= 0.75:
		_stage_bar_fill.color = Color("#ffeb3b")
	else:
		_stage_bar_fill.color = Color("#9bbc0f")

	# Countdown logo abaixo
	var remaining: float = max(0.0, BOSS_SPAWN_TIME - GameState.run_time)
	if remaining > 0.0:
		_boss_countdown_label.text = "BOSS EM %s" % _format_time(remaining)
		_boss_countdown_label.visible = true
	else:
		_boss_countdown_label.text = "BOSS!"
		_boss_countdown_label.visible = true

	# Texto "FASE 1 — Wave X" muda conforme avanços
	var stage_text := "FASE 1"
	if GameState.run_time < MINI_BOSS_TIMES[0]:
		stage_text += " — WAVE INICIAL"
	elif GameState.run_time < MINI_BOSS_TIMES[1]:
		stage_text += " — WAVE 2"
	elif GameState.run_time < MINI_BOSS_TIMES[2]:
		stage_text += " — WAVE 3"
	elif GameState.run_time < BOSS_SPAWN_TIME:
		stage_text += " — WAVE FINAL"
	else:
		stage_text += " — BOSS"
	_stage_label.text = stage_text


func _update_combo_visual(delta: float) -> void:
	if _combo_label == null:
		return
	# Reseta combo se passar a janela sem novos kills.
	if GameState.combo > 0 and GameState.combo_last_kill_at >= 0.0:
		if GameState.run_time - GameState.combo_last_kill_at > GameState.COMBO_WINDOW:
			GameState.combo = 0
			EventBus.combo_changed.emit(0)
	# Pulso de tamanho que decai.
	if _combo_pulse > 0.0:
		_combo_pulse -= delta * 4.0
		var s: float = 1.0 + maxf(0.0, _combo_pulse) * 0.3
		_combo_label.scale = Vector2(s, s)
	else:
		_combo_label.scale = Vector2.ONE


func _on_combo_changed(combo: int) -> void:
	if combo < 3:
		_combo_label.visible = false
		return
	_combo_label.visible = true
	_combo_label.text = "COMBO x%d" % combo
	_combo_pulse = 1.0
	# Cor escala com o tamanho do combo: laranja → vermelho → amarelo.
	var color: Color
	if combo >= 20:
		color = Color("#ffeb3b")
	elif combo >= 10:
		color = Color("#ff5252")
	else:
		color = Color("#ff9800")
	_combo_label.add_theme_color_override("font_color", color)


func _format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func _on_hp_changed(_amount: int, current: int, maximum: int) -> void:
	_update_hp(current, maximum)


func _update_hp(current: int, maximum: int) -> void:
	if maximum <= 0:
		return
	var t: float = clampf(float(current) / float(maximum), 0.0, 1.0)
	_hp_bar.size = Vector2(136.0 * t, 8)
	_hp_label.text = I18n.tf("hud_hp", [current, maximum])


func _on_xp_changed(_amount: int, current: int, needed: int) -> void:
	if needed <= 0:
		return
	var t: float = clampf(float(current) / float(needed), 0.0, 1.0)
	_xp_bar.size = Vector2((float(VIEWPORT_W) - 4.0) * t, 8)


func _on_level_up(new_level: int) -> void:
	_level_label.text = I18n.tf("hud_level", [new_level])
	# Mantém a barra em 100% até o modal fechar — XpSystem.refresh_bar() repinta
	# com o XP residual em _on_level_up_choice_made.


func _on_level_up_choice_made(_cartridge_id: String) -> void:
	XpSystem.refresh_bar()


func _on_cartridge_changed(_id: String) -> void:
	if _player == null:
		return
	for child in _cartridge_box.get_children():
		child.queue_free()
	for id in _player.equipped_cartridges.keys():
		var level: int = _player.equipped_cartridges[id]
		var def: CartridgeRegistry.CartridgeDef = CartridgeRegistry.get_def(id)
		var slot := _make_cartridge_slot(def, level)
		_cartridge_box.add_child(slot)


func _on_boss_warning() -> void:
	_warning_label.text = I18n.t("hud_warning_boss")
	_warning_label.visible = true
	_warning_timer = 6.0


func _on_boss_spawned(_boss: Node2D) -> void:
	var era: EraRegistry.EraDef = EraRegistry.get_def(GameState.selected_era_id)
	if era != null:
		_boss_name.text = era.boss_display_name.to_upper()
	_boss_name.visible = true
	_boss_bar_bg.visible = true
	_boss_bar.visible = true
	# Esconde a barra de progresso da fase quando o boss aparece —
	# o espaço passa a ser ocupado pela barra de vida do boss.
	if _stage_bar_root != null:
		_stage_bar_root.visible = false


func _on_boss_damaged(current: int, maximum: int) -> void:
	if maximum <= 0:
		return
	var t: float = clampf(float(current) / float(maximum), 0.0, 1.0)
	_boss_bar.size = Vector2(316.0 * t, 6)


func _on_boss_defeated() -> void:
	_boss_name.text = I18n.t("hud_purged")
	_boss_name.add_theme_color_override("font_color", Color("#9bbc0f"))
	_boss_bar.visible = false
	_boss_bar_bg.visible = false


func _make_cartridge_slot(def: CartridgeRegistry.CartridgeDef, level: int) -> Control:
	var ctrl := Control.new()
	ctrl.custom_minimum_size = Vector2(20, 16)
	var rect := ColorRect.new()
	rect.color = CartridgeRegistry.rarity_color(def.rarity)
	rect.size = Vector2(16, 12)
	rect.position = Vector2(2, 2)
	ctrl.add_child(rect)
	var lbl := Label.new()
	lbl.text = str(level)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.position = Vector2(5, -2)
	ctrl.add_child(lbl)
	return ctrl
