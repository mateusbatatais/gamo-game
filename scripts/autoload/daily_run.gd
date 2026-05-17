## Run Diária — uma seed compartilhada por dia (UTC). Todos jogadores recebem
## a mesma sequência de spawns, ofertas de level-up e drops, criando um desafio
## comparável. Score do dia fica salvo + histórico dos últimos 7 dias.
extends Node

const HISTORY_DAYS := 7  ## quantos dias guardar no histórico

## Seed do dia atual — derivada de yyyy*10000 + mm*100 + dd.
var today_seed: int = 0
## True se o usuário já completou (ou perdeu) a run diária de hoje.
var today_completed: bool = false
## Score da run diária de hoje (se completada), 0 caso contrário.
## Score = kills * 10 + time_seconds + max_combo * 5 + (10000 se vitória).
var today_score: int = 0
## Histórico: Array de Dictionary {date: "yyyy-mm-dd", score: int, victory: bool}.
var history: Array = []
## Marca se a run em andamento é a diária (pra aplicar seed ao mundo).
var run_in_progress_is_daily: bool = false

const SAVE_PATH := "user://daily_run.cfg"


func _ready() -> void:
	_compute_today_seed()
	load_state()
	EventBus.run_ended.connect(_on_run_ended)


func _compute_today_seed() -> void:
	var d: Dictionary = Time.get_date_dict_from_system(true)  # UTC
	var y: int = int(d.get("year", 2026))
	var m: int = int(d.get("month", 1))
	var day: int = int(d.get("day", 1))
	today_seed = y * 10000 + m * 100 + day


## Inicia uma run diária. Aplica a seed global pra que spawns/drops sejam determinísticos.
func start_daily_run() -> bool:
	if today_completed:
		return false
	seed(today_seed)
	run_in_progress_is_daily = true
	return true


## Limpa flag — chamado quando uma run normal começa após uma diária.
func clear_daily_flag() -> void:
	run_in_progress_is_daily = false


func _on_run_ended(victory: bool, stats: Dictionary) -> void:
	if not run_in_progress_is_daily:
		return
	run_in_progress_is_daily = false
	# Calcula score combinando os fatores.
	var kills: int = int(stats.get("kills", 0))
	var time_s: int = int(stats.get("time", 0.0))
	var max_combo: int = int(stats.get("max_combo", 0))
	var score: int = kills * 10 + time_s + max_combo * 5
	if victory:
		score += 10000
	today_completed = true
	today_score = score
	# Adiciona ao histórico (sobrescreve se já tem entry com mesma data).
	var date_str: String = _date_string()
	var existing: int = -1
	for i in history.size():
		if history[i].get("date", "") == date_str:
			existing = i
			break
	var entry: Dictionary = {
		"date": date_str,
		"score": score,
		"victory": victory,
	}
	if existing >= 0:
		history[existing] = entry
	else:
		history.push_front(entry)
	while history.size() > HISTORY_DAYS:
		history.pop_back()
	save_state()


func _date_string() -> String:
	var d: Dictionary = Time.get_date_dict_from_system(true)
	return "%04d-%02d-%02d" % [d.get("year", 2026), d.get("month", 1), d.get("day", 1)]


## Re-checa se mudou de dia (caso o jogador deixe o jogo aberto após meia-noite).
## Resetar today_completed se for novo dia.
func refresh_for_new_day() -> void:
	var old_seed: int = today_seed
	_compute_today_seed()
	if today_seed != old_seed:
		today_completed = false
		today_score = 0
		save_state()


func save_state() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("daily", "today_seed", today_seed)
	cfg.set_value("daily", "today_completed", today_completed)
	cfg.set_value("daily", "today_score", today_score)
	cfg.set_value("daily", "history", history)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Falha ao salvar daily_run: %s" % err)


func load_state() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var saved_seed: int = cfg.get_value("daily", "today_seed", 0)
	# Se a seed salva é do mesmo dia, restaura completion. Senão, reset.
	if saved_seed == today_seed:
		today_completed = cfg.get_value("daily", "today_completed", false)
		today_score = cfg.get_value("daily", "today_score", 0)
	var raw_history: Array = cfg.get_value("daily", "history", [])
	history.clear()
	for entry in raw_history:
		if entry is Dictionary:
			history.append(entry)
