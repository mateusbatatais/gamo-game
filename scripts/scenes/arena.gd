## Arena de gameplay — Era 8-bit.
## Spawna player, ativa spawner, instancia HUD/LevelUpModal e gerencia o boss.
extends Node2D

const ARENA_RECT := Rect2(Vector2.ZERO, Vector2(640, 360))
# Cada fase agora dura 3 minutos. Run completa = 2 fases × 3 min = 6 min total.
const BOSS_WARNING_TIME := 170.0  # 2:50
const BOSS_SPAWN_TIME := 180.0    # 3:00
# 2 mini-bosses por fase pra dar picos de tensão.
const MINI_BOSS_TIMES := [60.0, 130.0]
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
var _mini_boss_spawned: Array[bool] = [false, false]
var _intro_in_progress: bool = false

# Eventos ambientais: dispara um aleatório a cada ENV_EVENT_INTERVAL (com jitter).
const ENV_EVENT_INTERVAL_MIN := 30.0
const ENV_EVENT_INTERVAL_MAX := 50.0
var _env_event_timer: float = 0.0
var _env_event_active: bool = false


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
	Music.play_normal_for_era(GameState.selected_era_id)


func _build_camera() -> void:
	# Camera2D fixa no centro da arena (mesmo tamanho do viewport), só usada
	# para gerar shake via offset durante eventos de impacto.
	_camera = Camera2D.new()
	_camera.position = ARENA_RECT.get_center()
	_camera.make_current()
	add_child(_camera)


## Dispara um screen shake: amplitude em pixels, duração em segundos.
## Chamado por eventos de impacto (dano no player, morte de boss, etc).
## Respeita Settings.screen_shake (desliga totalmente) e photosensitive_mode (50%).
func trigger_shake(amplitude: float, duration: float = 0.22) -> void:
	if not Settings.screen_shake:
		return
	if Settings.photosensitive_mode:
		amplitude *= 0.5
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
	# Toast de lore cards (combos mid-run podem desbloquear cartas).
	var card_toast := LoreCardToast.new()
	add_child(card_toast)
	# Tutorial — só aparece se ainda não foi visto.
	if not GameState.tutorial_seen:
		add_child(TutorialOverlay.new())


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
	# Vincula o BoonSystem ao player (precisa estar após upgrades pra ter snapshots corretos).
	BoonSystem.bind_player(_player)
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
	_spawn_dialog(
		"ALERTA CRÍTICO",
		"Corruption nível máximo. Boss se materializando em 10s.",
		Color("#ff5252")
	)


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
	_check_environmental_events(delta)
	if not _boss_warning_shown and GameState.run_time >= BOSS_WARNING_TIME:
		_boss_warning_shown = true
		EventBus.boss_warning.emit()
	if not _boss_spawned and GameState.run_time >= BOSS_SPAWN_TIME:
		_spawn_boss()


## Decrementa o timer de eventos ambientais e dispara um aleatório quando zerar.
## Não dispara durante o boss ou nos primeiros/últimos 20s da fase.
func _check_environmental_events(delta: float) -> void:
	if _boss_spawned or _env_event_active:
		return
	if GameState.run_time < 20.0:
		return
	if GameState.run_time > BOSS_SPAWN_TIME - 25.0:
		return
	_env_event_timer -= delta
	if _env_event_timer <= 0.0:
		_env_event_timer = randf_range(ENV_EVENT_INTERVAL_MIN, ENV_EVENT_INTERVAL_MAX)
		_spawn_environmental_event()


func _spawn_environmental_event() -> void:
	var event := EnvironmentalEvent.new()
	event.kind = randi() % EnvironmentalEvent.Kind.size()
	_entity_root.add_child(event)
	_env_event_active = true
	# Dialog avisando o player
	var names := {
		EnvironmentalEvent.Kind.DATA_STORM: ["DATA STORM", Color("#ff5252")],
		EnvironmentalEvent.Kind.BIT_RAIN: ["BIT RAIN", Color("#69f0ae")],
		EnvironmentalEvent.Kind.GLITCH_WAVE: ["GLITCH WAVE", Color("#e040fb")],
	}
	var data: Array = names[event.kind]
	_spawn_dialog("ALERTA", "%s detectado!" % data[0], data[1] as Color)
	# Quando o evento terminar, libera pra spawnar outro.
	event.tree_exited.connect(func(): _env_event_active = false)


func _check_mini_boss_spawn() -> void:
	if _boss_spawned:
		return
	for i in MINI_BOSS_TIMES.size():
		if _mini_boss_spawned[i]:
			continue
		if GameState.run_time >= MINI_BOSS_TIMES[i]:
			_mini_boss_spawned[i] = true
			_spawn_mini_boss(i)
			EventBus.mini_boss_spawned.emit()


func _spawn_mini_boss(wave_index: int = 0) -> void:
	# Mini-boss específico por era — atualmente 3 variantes.
	var mb: MiniBoss
	var name_label: String
	var accent: Color
	var era_quote: String
	match GameState.selected_era_id:
		"era_32bit_cd":
			mb = MiniBossDiscReader.new()
			name_label = "Disc Reader"
			accent = Color("#00e5ff")
			era_quote = "Setor corrompido girando. Disc Reader online."
		"era_64bit":
			mb = MiniBossZBuffer.new()
			name_label = "Z-Buffer"
			accent = Color("#7e57c2")
			era_quote = "Polígonos colidindo. Z-Buffer ativado."
		_:
			mb = MiniBoss.new()
			name_label = "Sentinel"
			accent = Color("#e040fb")
			era_quote = "Pico de corrupção detectado. Sentinel se manifesta."
	var origin := ArenaBounds.random_spawn_point(40.0)
	mb.global_position = origin
	_entity_root.add_child(mb)
	trigger_shake(5.0, 0.35)
	# Quote varia ligeiramente por wave também (1ª = intro da era, 2ª = "reforçado").
	if wave_index >= 1:
		era_quote = "Outro %s. O Glitch está adaptando." % name_label
	_spawn_dialog("GAMO.SYS", era_quote, accent)


func _spawn_dialog(speaker: String, message: String, accent: Color) -> void:
	var dlg := DialogBox.new()
	add_child(dlg)
	dlg.show_message(speaker, message, accent)


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
	# Subtitle e cor variam por era pra dar identidade ao boss.
	var boss_subtitle: String = "- CHEFE FINAL -"
	var boss_color: Color = Color("#ff5252")
	match GameState.selected_era_id:
		"era_16bit":
			boss_subtitle = "- ERA 16-BIT • BOSS -"
			boss_color = Color("#9bbc0f")
		"era_32bit_cd":
			boss_subtitle = "- ERA 32-BIT CD • BOSS -"
			boss_color = Color("#00e5ff")
		"era_64bit":
			boss_subtitle = "- COLAPSO POLIGONAL • CHEFE FINAL -"
			boss_color = Color("#7e57c2")
	# Pausa, mostra title card + zoom, espera, retoma.
	get_tree().paused = true
	var intro := BossIntro.new()
	add_child(intro)
	intro.start(era.boss_display_name, boss_pos, _camera, boss_subtitle, boss_color)
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
		"BadSector":
			return BadSector.new()
		"PolygonHell":
			return PolygonHell.new()
	push_warning("Boss desconhecido: %s" % class_id)
	return Fragmentation.new()


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
	_spawn_dialog(
		"GAMO.SYS",
		"Era purificada. Coleção restaurada. Cartucho recuperado.",
		Color("#9bbc0f")
	)
	await get_tree().create_timer(2.0, true, false, true).timeout
	# Se for a última fase da run, roda a cinemática de vitória final.
	if GameState.is_last_stage():
		await _play_victory_sequence()
		_end_run(true)
	else:
		_show_stage_cleared()


## Roda a sequência cinemática de vitória ao derrotar o boss final da run.
func _play_victory_sequence() -> void:
	var center := ARENA_RECT.get_center()
	if _player != null:
		center = _player.global_position
	var vs := VictorySequence.new()
	_entity_root.add_child(vs)
	vs.start(center)
	await vs.finished
	vs.queue_free()


## Mostra o overlay "STAGE CLEARED" e aguarda o player avançar pra próxima fase.
func _show_stage_cleared() -> void:
	var cleared := StageCleared.new()
	add_child(cleared)
	var next_era_id: String = GameState.stages_in_run[GameState.stage_index + 1]
	var next_def: EraRegistry.EraDef = EraRegistry.get_def(next_era_id)
	var next_name: String = next_def.display_name if next_def != null else "?"
	var stats := {
		"time": GameState.run_time,
		"kills": GameState.run_kills,
		"max_combo": GameState.last_run_max_combo,
		"tokens": GameState.run_tokens_earned,
	}
	cleared.show_for_stage(GameState.stage_label(), next_name, stats)
	await cleared.advance_requested
	cleared.queue_free()
	# Mini-puzzle opcional entre fases — restaure o cartucho.
	# Acerto = cura + bônus tokens. Skip/erro = sem punição.
	await _run_inter_stage_puzzle()
	_advance_stage()


## Roda o puzzle de "restaurar cartucho" entre fases. Vitória recompensa o player
## com cura total + 80 tokens. Pulou ou errou: segue direto sem bônus.
## Pausa o gameplay durante o puzzle pra não ter inimigos/spawner rodando no fundo.
func _run_inter_stage_puzzle() -> void:
	var puzzle := CartridgePuzzle.new()
	add_child(puzzle)
	puzzle.start()  ## inicializa em INTRO — player aperta ENTER pra começar
	get_tree().paused = true
	var success: bool = await puzzle.completed
	get_tree().paused = false
	puzzle.queue_free()
	if success and _player != null and is_instance_valid(_player):
		_player.heal(_player.max_hp)  # cura total
		GameState.grant_tokens(80)
		_spawn_dialog(
			"GAMO.SYS",
			"Cartucho restaurado. Energia recarregada. +80 tokens.",
			Color("#9bbc0f")
		)


## Avança a arena pra próxima fase: limpa tudo, configura nova era, recomeça spawn.
func _advance_stage() -> void:
	if not GameState.advance_to_next_stage():
		_end_run(true)
		return
	# Limpa o que sobrou da fase anterior.
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy:
			(e as Enemy).queue_free()
	for node in _entity_root.get_children():
		if node is EnemyProjectile or node is XpGem or node is HealthPickup or node is PowerUp:
			node.queue_free()
	# Reset estado da fase.
	_boss_warning_shown = false
	_boss_spawned = false
	_mini_boss_spawned[0] = false
	_mini_boss_spawned[1] = false
	# Troca paleta do background pra nova era.
	if _bg_canvas != null and _bg_canvas.has_method("set_era"):
		_bg_canvas.call("set_era", GameState.selected_era_id)
	# Reseta spawner com pool de inimigos da nova era.
	if _spawner != null:
		_spawner.reset_for_new_stage()
	# Player ganha tier de armadura novo (T1 → T2 → T3 conforme a fase).
	if _player != null and is_instance_valid(_player):
		_player.update_visual_tier_for_stage()
	# HUD atualiza barra de progresso (run_time foi resetado em GameState).
	_spawn_dialog(
		"GAMO.SYS",
		"Atravessando pra %s..." % EraRegistry.get_def(GameState.selected_era_id).display_name,
		Color("#00e5ff")
	)
	# Banner dramático "FASE X — ERA Y  ▲ DIFICULDADE +Z% ▲"
	var banner := StageBanner.new()
	add_child(banner)
	var difficulty_pct: int = int(round((GameState.stage_difficulty_mult() - 1.0) * 100.0))
	banner.show_stage(
		GameState.stage_index + 1,
		EraRegistry.get_def(GameState.selected_era_id).display_name,
		difficulty_pct
	)
	Music.play_normal_for_era(GameState.selected_era_id)  # nova era, nova track


func _boss_reward_cartridge_for(era_id: String) -> String:
	match era_id:
		"era_8bit":
			return "reset_button"
		"era_16bit":
			return "region_free"
		"era_32bit_cd":
			return "heat_seeker"  # cartucho da era CD
		"era_64bit":
			return "reflector"  # cartucho legendary defensivo da era poligonal
	return ""


func _end_run(victory: bool) -> void:
	if _ended:
		return
	_ended = true
	GameState.end_run(victory)
	Music.stop()
	# Pausa curta — vitória/derrota já tiveram suas cinemáticas próprias
	# (boss death slow-mo / player death sequence).
	await get_tree().create_timer(0.5, true, false, true).timeout
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
