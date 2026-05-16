## Estado global do jogo: progresso persistente entre runs + estado da run atual.
extends Node

const SAVE_PATH := "user://save.cfg"

# --- Persistente (sobrevive entre runs) ---
var collected_cartridges: Array[String] = []
var best_run_time: float = 0.0
var total_runs: int = 0
var total_kills: int = 0
var selected_spirit_id: String = "pixel"
var selected_era_id: String = "era_16bit"
var bosses_defeated: Array[String] = []  ## ids de bosses derrotados
var memory_tokens: int = 0  ## moeda persistente, gasta na hub
var upgrade_levels: Dictionary = {}  ## id (String) -> level (int)
var achievements_unlocked: Array[String] = []
# Stats de run (capturados pra game-over)
var last_run_damage_dealt: int = 0
var last_run_max_combo: int = 0
var last_run_tokens_earned: int = 0
# Stats acumulados pra achievements
var max_combo_ever: int = 0
var total_tokens_earned: int = 0
# Stats da run atual (correntes)
var run_damage_dealt: int = 0
var run_tokens_earned: int = 0

# --- Run atual ---
var run_time: float = 0.0
var run_kills: int = 0
var run_active: bool = false
var last_run_victory: bool = false

# Estados temporários (controlados por power-ups e similares)
var enemies_frozen_until: float = -1.0
var combo: int = 0
var combo_last_kill_at: float = -1.0
const COMBO_WINDOW := 1.8


func _ready() -> void:
	load_progress()
	EventBus.player_damaged.connect(_on_player_damaged)


func _on_player_damaged(_amount: int, _current: int, _maximum: int) -> void:
	# Tomar dano quebra o combo — pressão pra jogar sem tomar dano.
	break_combo()


## Reseta o combo imediatamente. Usado por player_damaged e situações similares.
func break_combo() -> void:
	if combo == 0:
		return
	combo = 0
	combo_last_kill_at = -1.0
	EventBus.combo_changed.emit(0)


func start_run() -> void:
	run_time = 0.0
	run_kills = 0
	run_active = true
	enemies_frozen_until = -1.0
	combo = 0
	combo_last_kill_at = -1.0
	run_damage_dealt = 0
	run_tokens_earned = 0
	total_runs += 1
	EventBus.run_started.emit()


func end_run(victory: bool) -> void:
	run_active = false
	last_run_victory = victory
	if run_time > best_run_time:
		best_run_time = run_time
	# Captura snapshot dos stats pra tela de game-over.
	last_run_damage_dealt = run_damage_dealt
	last_run_max_combo = max(combo, last_run_max_combo)
	last_run_tokens_earned = run_tokens_earned
	var stats := {
		"time": run_time,
		"kills": run_kills,
		"victory": victory,
		"damage": run_damage_dealt,
		"tokens": run_tokens_earned,
		"max_combo": last_run_max_combo,
	}
	EventBus.run_ended.emit(victory, stats)
	save_progress()


## Concede tokens (chamado por enemy._die). Atualiza stats e propaga via EventBus.
func grant_tokens(amount: int) -> void:
	if amount <= 0:
		return
	memory_tokens += amount
	run_tokens_earned += amount
	total_tokens_earned += amount
	EventBus.tokens_changed.emit(memory_tokens)


## Tenta gastar X tokens. Retorna true se conseguiu.
func spend_tokens(amount: int) -> bool:
	if memory_tokens < amount:
		return false
	memory_tokens -= amount
	EventBus.tokens_changed.emit(memory_tokens)
	save_progress()
	return true


func get_upgrade_level(id: String) -> int:
	return upgrade_levels.get(id, 0)


func increment_upgrade(id: String) -> void:
	upgrade_levels[id] = get_upgrade_level(id) + 1
	save_progress()


func register_damage_dealt(amount: int) -> void:
	run_damage_dealt += amount


func is_achievement_unlocked(id: String) -> bool:
	return id in achievements_unlocked


func unlock_achievement(id: String) -> void:
	if id in achievements_unlocked:
		return
	achievements_unlocked.append(id)
	EventBus.achievement_unlocked.emit(id)
	save_progress()


func register_kill() -> void:
	run_kills += 1
	total_kills += 1
	# Atualiza combo: se passou da janela, reseta.
	if combo_last_kill_at < 0.0 or run_time - combo_last_kill_at > COMBO_WINDOW:
		combo = 1
	else:
		combo += 1
	combo_last_kill_at = run_time
	if combo > max_combo_ever:
		max_combo_ever = combo
	if combo > last_run_max_combo:
		last_run_max_combo = combo
	EventBus.combo_changed.emit(combo)


func is_enemies_frozen() -> bool:
	return run_active and run_time < enemies_frozen_until


func freeze_enemies_for(duration: float) -> void:
	enemies_frozen_until = run_time + duration


func collect_cartridge(cartridge_id: String) -> void:
	if cartridge_id in collected_cartridges:
		return
	collected_cartridges.append(cartridge_id)
	EventBus.cartridge_collected.emit(cartridge_id)


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "collected_cartridges", collected_cartridges)
	cfg.set_value("progress", "best_run_time", best_run_time)
	cfg.set_value("progress", "total_runs", total_runs)
	cfg.set_value("progress", "total_kills", total_kills)
	cfg.set_value("progress", "selected_spirit_id", selected_spirit_id)
	cfg.set_value("progress", "selected_era_id", selected_era_id)
	cfg.set_value("progress", "bosses_defeated", bosses_defeated)
	cfg.set_value("progress", "memory_tokens", memory_tokens)
	cfg.set_value("progress", "upgrade_levels", upgrade_levels)
	cfg.set_value("progress", "achievements_unlocked", achievements_unlocked)
	cfg.set_value("progress", "max_combo_ever", max_combo_ever)
	cfg.set_value("progress", "total_tokens_earned", total_tokens_earned)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Falha ao salvar progresso: %s" % err)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var raw_cartridges: Array = cfg.get_value("progress", "collected_cartridges", [])
	collected_cartridges.clear()
	for c in raw_cartridges:
		if c is String:
			collected_cartridges.append(c)
	best_run_time = cfg.get_value("progress", "best_run_time", 0.0)
	total_runs = cfg.get_value("progress", "total_runs", 0)
	total_kills = cfg.get_value("progress", "total_kills", 0)
	selected_spirit_id = cfg.get_value("progress", "selected_spirit_id", "pixel")
	selected_era_id = cfg.get_value("progress", "selected_era_id", "era_16bit")
	# Migra saves antigos: 8-bit deixou de ser jogável.
	if selected_era_id == "era_8bit":
		selected_era_id = "era_16bit"
	var raw_bosses: Array = cfg.get_value("progress", "bosses_defeated", [])
	bosses_defeated.clear()
	for b in raw_bosses:
		if b is String:
			bosses_defeated.append(b)
	memory_tokens = cfg.get_value("progress", "memory_tokens", 0)
	var raw_upgrades = cfg.get_value("progress", "upgrade_levels", {})
	upgrade_levels = raw_upgrades if raw_upgrades is Dictionary else {}
	var raw_ach: Array = cfg.get_value("progress", "achievements_unlocked", [])
	achievements_unlocked.clear()
	for a in raw_ach:
		if a is String:
			achievements_unlocked.append(a)
	max_combo_ever = cfg.get_value("progress", "max_combo_ever", 0)
	total_tokens_earned = cfg.get_value("progress", "total_tokens_earned", 0)


func register_boss_defeat(boss_id: String) -> void:
	if boss_id in bosses_defeated:
		return
	bosses_defeated.append(boss_id)


func _process(delta: float) -> void:
	if run_active:
		run_time += delta
