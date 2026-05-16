## Arena de gameplay — Era 8-bit.
## Spawna player, ativa spawner, instancia HUD/LevelUpModal e gerencia o boss.
extends Node2D

const ARENA_RECT := Rect2(Vector2.ZERO, Vector2(640, 360))
# Boss spawn ampliado para 6 minutos pra dar tempo de ver toda a curva de progressão.
const BOSS_WARNING_TIME := 350.0  # 5:50
const BOSS_SPAWN_TIME := 360.0    # 6:00
# 3 mini-bosses cronometrados a cada ~1:30, distribuindo os picos de tensão.
const MINI_BOSS_TIMES := [90.0, 210.0, 330.0]
const FREEZE_DURATION := 3.0

var _player: Player
var _hud: HUD
var _level_up_modal: LevelUpModal
var _pause_menu: PauseMenu
var _entity_root: Node2D
var _spawner: EnemySpawner
var _bg_canvas: Node2D
var _boss_warning_shown: bool = false
var _boss_spawned: bool = false
var _ended: bool = false

var _camera: Camera2D
var _shake_remaining: float = 0.0
var _shake_amplitude: float = 0.0
var _shake_initial_duration: float = 0.25
var _mini_boss_spawned: Array[bool] = [false, false, false]
var _intro_in_progress: bool = false


func _ready() -> void:
	ArenaBounds.set_rect(ARENA_RECT)
	_build_background()
	_build_entity_root()
	_spawn_player()
	_build_spawner()
	_build_hud()
	_build_level_up_modal()
	_build_pause_menu()
	_build_camera()
	_connect_signals()
	GameState.start_run()
	Music.play_normal()


func _build_camera() -> void:
	# Camera2D fixa no centro da arena (mesmo tamanho do viewport), só usada
	# para gerar shake via offset durante eventos de impacto.
	_camera = Camera2D.new()
	_camera.position = ARENA_RECT.get_center()
	_camera.make_current()
	add_child(_camera)


## Dispara um screen shake: amplitude em pixels, duração em segundos.
## Chamado por eventos de impacto (dano no player, morte de boss, etc).
func trigger_shake(amplitude: float, duration: float = 0.22) -> void:
	if amplitude > _shake_amplitude:
		_shake_amplitude = amplitude
	if duration > _shake_remaining:
		_shake_remaining = duration
		_shake_initial_duration = duration


func _update_shake(delta: float) -> void:
	if _camera == null:
		return
	if _shake_remaining <= 0.0:
		_camera.offset = Vector2.ZERO
		_shake_amplitude = 0.0
		return
	_shake_remaining -= delta
	var decay: float = clampf(_shake_remaining / max(0.001, _shake_initial_duration), 0.0, 1.0)
	var amp: float = _shake_amplitude * decay
	_camera.offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	if _shake_remaining <= 0.0:
		_camera.offset = Vector2.ZERO
		_shake_amplitude = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if _ended:
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	# Não pausa por cima do modal de level-up ou se já estiver pausado por ele.
	if _level_up_modal != null and _level_up_modal.visible:
		return
	_pause_menu.toggle()
	get_viewport().set_input_as_handled()


func _build_pause_menu() -> void:
	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	# Toast de conquistas escuta o EventBus globalmente.
	var toast := AchievementToast.new()
	add_child(toast)


func _build_background() -> void:
	_bg_canvas = ArenaBackground.new()
	add_child(_bg_canvas)


func _build_entity_root() -> void:
	_entity_root = Node2D.new()
	_entity_root.name = "Entities"
	add_child(_entity_root)


func _spawn_player() -> void:
	_player = Player.new()
	var spirit: SpiritRegistry.SpiritDef = SpiritRegistry.get_def(GameState.selected_spirit_id)
	if spirit == null:
		spirit = SpiritRegistry.get_def("pixel")
	_player.apply_spirit(spirit)
	_player.global_position = ARENA_RECT.get_center()
	_entity_root.add_child(_player)
	# Aplica upgrades persistentes da hub antes do primeiro cartucho.
	UpgradeRegistry.apply_to_player(_player)
	_player.equip_cartridge(spirit.starting_cartridge)


func _build_spawner() -> void:
	_spawner = EnemySpawner.new()
	_spawner.arena_container_path = NodePath("../Entities")
	add_child(_spawner)


func _build_hud() -> void:
	_hud = HUD.new()
	add_child(_hud)
	_hud.bind_player(_player)


func _build_level_up_modal() -> void:
	_level_up_modal = LevelUpModal.new()
	_level_up_modal.visible = false
	add_child(_level_up_modal)


func _connect_signals() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.level_up_choice_made.connect(_on_cartridge_chosen)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.player_damaged.connect(_on_player_damaged_shake)
	EventBus.boss_defeated.connect(_on_boss_defeated_shake)
	EventBus.power_up_collected.connect(_on_power_up_collected)
	EventBus.boss_warning.connect(_on_boss_warning_music)


func _on_boss_warning_music() -> void:
	Music.play_boss()


func _on_power_up_collected(kind: int) -> void:
	match kind:
		PowerUp.Kind.FREEZE:
			GameState.freeze_enemies_for(FREEZE_DURATION)
			trigger_shake(2.0, 0.2)
		PowerUp.Kind.NUKE:
			_apply_nuke()
		PowerUp.Kind.MAGNET:
			_apply_magnet()


func _apply_nuke() -> void:
	trigger_shake(12.0, 0.55)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Enemy):
			continue
		if e is Stain:
			continue
		# Boss e mini-boss sobrevivem mas levam dano grande.
		if e.is_in_group("boss"):
			(e as Enemy).take_damage(80)
		else:
			(e as Enemy).take_damage(9999)


func _apply_magnet() -> void:
	if _player == null:
		return
	# Teleporta todas as gemas de XP visíveis pra cima do player —
	# elas serão coletadas no próximo frame pela própria lógica de attract.
	for node in _entity_root.get_children():
		if node is XpGem:
			(node as XpGem).global_position = _player.global_position


func _on_player_damaged_shake(_amount: int, _current: int, _maximum: int) -> void:
	trigger_shake(4.0, 0.18)


func _on_boss_defeated_shake() -> void:
	trigger_shake(8.0, 0.6)


func _process(delta: float) -> void:
	_update_shake(delta)
	if _ended:
		return
	_check_mini_boss_spawn()
	if not _boss_warning_shown and GameState.run_time >= BOSS_WARNING_TIME:
		_boss_warning_shown = true
		EventBus.boss_warning.emit()
	if not _boss_spawned and GameState.run_time >= BOSS_SPAWN_TIME:
		_spawn_boss()


func _check_mini_boss_spawn() -> void:
	if _boss_spawned:
		return
	for i in MINI_BOSS_TIMES.size():
		if _mini_boss_spawned[i]:
			continue
		if GameState.run_time >= MINI_BOSS_TIMES[i]:
			_mini_boss_spawned[i] = true
			_spawn_mini_boss()
			EventBus.mini_boss_spawned.emit()


func _spawn_mini_boss() -> void:
	var mb := MiniBoss.new()
	# Spawna numa borda aleatória da arena, fora da câmera por um instante.
	var origin := ArenaBounds.random_spawn_point(40.0)
	mb.global_position = origin
	_entity_root.add_child(mb)
	trigger_shake(5.0, 0.35)


func _spawn_boss() -> void:
	_boss_spawned = true
	_spawner.enabled = false
	# Limpa todos os mobs e projéteis pra dar uma "arena limpa" pro boss.
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and not (e is Stain) and not (e.is_in_group("boss")):
			(e as Enemy).queue_free()
	for node in _entity_root.get_children():
		if node is EnemyProjectile:
			node.queue_free()

	var era: EraRegistry.EraDef = EraRegistry.get_def(GameState.selected_era_id)
	if era == null:
		era = EraRegistry.get_def("era_16bit")
	var boss := _instantiate_boss(era.boss_class_name)
	if boss == null:
		return
	var boss_pos := Vector2(ARENA_RECT.get_center().x, ARENA_RECT.position.y + 50.0)
	boss.global_position = boss_pos
	# Pausa, mostra title card + zoom, espera, retoma.
	get_tree().paused = true
	var intro := BossIntro.new()
	add_child(intro)
	intro.start(era.boss_display_name, boss_pos, _camera)
	await intro.finished
	intro.queue_free()
	_entity_root.add_child(boss)
	trigger_shake(10.0, 0.6)
	get_tree().paused = false


func _instantiate_boss(class_id: String) -> Enemy:
	match class_id:
		"CorruptionV1":
			return CorruptionV1.new()
		"Fragmentation":
			return Fragmentation.new()
	push_warning("Boss desconhecido: %s" % class_id)
	return CorruptionV1.new()


func _on_player_died() -> void:
	_end_run(false)


func _on_boss_defeated() -> void:
	var era_id := GameState.selected_era_id
	GameState.register_boss_defeat(era_id)
	# Drop específico por era
	var reward_cartridge := _boss_reward_cartridge_for(era_id)
	if reward_cartridge != "":
		_player.equip_cartridge(reward_cartridge)
		GameState.collect_cartridge(reward_cartridge)
	await get_tree().create_timer(2.0, true, false, true).timeout
	_end_run(true)


func _boss_reward_cartridge_for(era_id: String) -> String:
	match era_id:
		"era_8bit":
			return "reset_button"
		"era_16bit":
			return "region_free"
	return ""


func _end_run(victory: bool) -> void:
	if _ended:
		return
	_ended = true
	GameState.end_run(victory)
	Music.stop()
	await get_tree().create_timer(1.5, true, false, true).timeout
	SceneRouter.go_to_game_over()


func _on_level_up(_new_level: int) -> void:
	_try_show_level_up()


func _try_show_level_up() -> void:
	if not XpSystem.has_pending_levelup():
		return
	if _level_up_modal.visible or _intro_in_progress:
		return
	XpSystem.consume_levelup()
	var choices := CartridgeRegistry.roll_choices(_player.equipped_cartridges, 3)
	if choices.is_empty():
		return
	# Roda a intro animada antes de abrir o modal: explosões em cascata
	# nos inimigos da tela + "LEVEL UP!" pulsando. Depois mostra as cartas.
	_intro_in_progress = true
	await _play_level_up_intro()
	_intro_in_progress = false
	_level_up_modal.show_choices(choices, _player.equipped_cartridges)


func _play_level_up_intro() -> void:
	# Pausa a árvore — intro processa via PROCESS_MODE_ALWAYS.
	get_tree().paused = true
	# Coleta posições dos inimigos comuns e remove eles (boss/miniboss sobrevivem).
	var positions: Array[Vector2] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Enemy):
			continue
		if (e as Enemy).is_in_group("boss"):
			continue
		positions.append((e as Enemy).global_position)
		(e as Enemy).queue_free()
	# Limpa projéteis inimigos junto pra não ficarem perdidos na pausa.
	for node in _entity_root.get_children():
		if node is EnemyProjectile:
			node.queue_free()

	# Spawn da intro no espaço-mundo (pra particles em posições world correctas).
	var intro := LevelUpIntro.new()
	_entity_root.add_child(intro)
	intro.start(positions)
	Audio.play(Audio.Sfx.LEVEL_UP)
	await intro.finished
	intro.queue_free()


func _on_cartridge_chosen(cartridge_id: String) -> void:
	# Se é uma evolução, consome os ingredientes antes de equipar
	if CartridgeRegistry.is_evolution(cartridge_id):
		var ingredients := CartridgeRegistry.ingredients_for(cartridge_id)
		for ing in ingredients:
			_player.unequip_cartridge(ing)
	_player.equip_cartridge(cartridge_id)
	GameState.collect_cartridge(cartridge_id)
	_clear_field()
	call_deferred("_try_show_level_up")


## Limpa inimigos comuns + projéteis + stains após escolher o cartucho de level-up.
## Boss e mini-boss continuam vivos. Dá uma sensação de "checkpoint" entre fases.
func _clear_field() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Enemy):
			continue
		if e.is_in_group("boss"):
			continue
		# Apaga sem dropar XP/health/power-up (caso contrário viraria farm fácil).
		(e as Enemy).queue_free()
	# Remove projéteis inimigos restantes pra não acertar o player no spawn da nova wave.
	for node in _entity_root.get_children():
		if node is EnemyProjectile:
			node.queue_free()
