## Registro de conquistas. Cada conquista tem id, nome, descrição e um check()
## que retorna true quando deve ser desbloqueada.
## O registro escuta eventos relevantes do EventBus pra disparar checks.
extends Node

class AchievementDef:
	var id: String
	var display_name: String
	var description: String
	var check: Callable  ## retorna bool

	func _init(p_id: String, p_name: String, p_desc: String, p_check: Callable) -> void:
		id = p_id
		display_name = p_name
		description = p_desc
		check = p_check


var _registry: Dictionary = {}
var _order: Array[String] = []


func _ready() -> void:
	_register_all()
	# Eventos que possivelmente desbloqueiam achievements.
	# Handlers tipados conforme aridade do signal pra evitar erro do conector do Godot 4.
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.cartridge_collected.connect(_on_cartridge_collected)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.run_ended.connect(_on_run_ended)


func _register_all() -> void:
	_add(AchievementDef.new(
		"first_kill", "Primeiro Sangue", "Mate seu primeiro inimigo.",
		func(): return GameState.total_kills >= 1
	))
	_add(AchievementDef.new(
		"kills_100", "Centena", "Acumule 100 abates totais.",
		func(): return GameState.total_kills >= 100
	))
	_add(AchievementDef.new(
		"kills_1000", "Limpeza Profunda", "Acumule 1.000 abates totais.",
		func(): return GameState.total_kills >= 1000
	))
	_add(AchievementDef.new(
		"kills_5000", "Apagador de Bug", "Acumule 5.000 abates totais.",
		func(): return GameState.total_kills >= 5000
	))
	_add(AchievementDef.new(
		"combo_25", "Sequência", "Faça um combo de 25 hits.",
		func(): return GameState.max_combo_ever >= 25
	))
	_add(AchievementDef.new(
		"combo_50", "Imparável", "Faça um combo de 50 hits.",
		func(): return GameState.max_combo_ever >= 50
	))
	_add(AchievementDef.new(
		"combo_100", "Maestro Glitch", "Faça um combo de 100 hits.",
		func(): return GameState.max_combo_ever >= 100
	))
	_add(AchievementDef.new(
		"collect_5", "Colecionador Iniciante", "Colete 5 cartuchos diferentes.",
		func(): return GameState.collected_cartridges.size() >= 5
	))
	_add(AchievementDef.new(
		"collect_10", "Estante Cheia", "Colete 10 cartuchos diferentes.",
		func(): return GameState.collected_cartridges.size() >= 10
	))
	_add(AchievementDef.new(
		"boss_kill", "Purgador", "Derrote o boss Fragmentation.",
		func(): return GameState.bosses_defeated.size() >= 1
	))
	_add(AchievementDef.new(
		"survive_5min", "Resistente", "Sobreviva 5 minutos em uma run.",
		func(): return GameState.best_run_time >= 300.0
	))
	_add(AchievementDef.new(
		"survive_full", "Maratonista", "Sobreviva os 6 minutos completos.",
		func(): return GameState.best_run_time >= 360.0
	))
	_add(AchievementDef.new(
		"tokens_500", "Memória Cheia", "Acumule 500 Tokens de Memória no total.",
		func(): return GameState.total_tokens_earned >= 500
	))


func _add(def: AchievementDef) -> void:
	_registry[def.id] = def
	_order.append(def.id)


func get_def(id: String) -> AchievementDef:
	return _registry.get(id, null)


func all_ids() -> Array[String]:
	return _order.duplicate()


func _on_enemy_killed(_enemy: Node2D, _xp_value: int) -> void:
	_check_all()


func _on_combo_changed(_combo: int) -> void:
	_check_all()


func _on_cartridge_collected(_cartridge_id: String) -> void:
	_check_all()


func _on_boss_defeated() -> void:
	_check_all()


func _on_run_ended(_v: bool, _stats: Dictionary) -> void:
	_check_all()


func _check_all() -> void:
	for id in _order:
		if GameState.is_achievement_unlocked(id):
			continue
		var def: AchievementDef = _registry[id]
		if def.check.call():
			GameState.unlock_achievement(id)
