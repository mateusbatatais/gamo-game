## Sistema de Special Power — habilidade única ativada por tecla X (ou botão Y
## do gamepad). Cada skin tem um efeito diferente. Limite de 3 charges por run.
## Refill +1 charge ao matar mini-boss (manter momentum).
##
## Skins atuais e seus specials:
##   GAMO (default)     — FREEZE NOVA: congela todos por 4s + nuke central
##   Cavaleiro          — SHIELD BASH: empurra todos pra fora + 2.5s invuln
##   Punk               — RAGE BURST: dispara 16 projéteis em todas direções
##   Ninja              — SHADOW STRIKE: teleporta + AoE dano nos próximos
##   Ciborgue           — OVERLOAD: cartuchos disparam 3x mais rápido por 6s
##   Hacker             — DEBUG MODE: invuln 4s + congelamento de inimigos
##   Gamer Retrô        — NUKE: dano massivo em todos inimigos visíveis
##   Mago do Codex      — ARCANE NOVA: explosão mágica em ondas concêntricas
##   Pixel Ghost        — PHASE OUT: invuln 5s + lifesteal em qualquer dano dado
extends Node

const MAX_CHARGES := 3
const STARTING_CHARGES := 3

signal charges_changed(current: int, maximum: int)
signal special_used(skin_id: String)

var _charges: int = STARTING_CHARGES


func _ready() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.mini_boss_spawned.connect(_on_mini_boss_warning)
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _on_run_started() -> void:
	_charges = STARTING_CHARGES
	charges_changed.emit(_charges, MAX_CHARGES)


## Mini-boss morrendo refill +1 charge (sinaliza via enemy_killed se for MiniBoss).
func _on_enemy_killed(enemy: Node2D, _xp: int) -> void:
	if enemy is MiniBoss:
		add_charge(1)


func _on_mini_boss_warning() -> void:
	pass  ## hook futuro pra UI


func charges() -> int:
	return _charges


func max_charges() -> int:
	return MAX_CHARGES


func add_charge(amount: int) -> void:
	_charges = min(MAX_CHARGES, _charges + amount)
	charges_changed.emit(_charges, MAX_CHARGES)


## Tenta usar o special. Retorna true se conseguiu (havia charge).
## Player chama isso em _handle_input quando aperta a tecla X.
func try_use(player: Player) -> bool:
	if _charges <= 0:
		Audio.play(Audio.Sfx.UI_ERROR)
		return false
	if player == null or not is_instance_valid(player):
		return false
	_charges -= 1
	charges_changed.emit(_charges, MAX_CHARGES)
	var skin_id: String = GameState.current_skin_id
	_execute_special(skin_id, player)
	special_used.emit(skin_id)
	Audio.play(Audio.Sfx.LEVEL_UP)
	HitStop.freeze_big()
	return true


## Dispatch — chama o handler do special apropriado pra skin.
func _execute_special(skin_id: String, player: Player) -> void:
	match skin_id:
		"knight":
			_special_shield_bash(player)
		"punk":
			_special_rage_burst(player)
		"ninja":
			_special_shadow_strike(player)
		"cyborg":
			_special_overload(player)
		"hacker":
			_special_debug_mode(player)
		"chubby":
			_special_nuke(player)
		"wizard":
			_special_arcane_nova(player)
		"ghost":
			_special_phase_out(player)
		_:  # default: GAMO + qualquer skin sem implementação
			_special_freeze_nova(player)


# --- Implementações dos specials ---

## GAMO default — congela 4s + dano radial nos próximos.
func _special_freeze_nova(player: Player) -> void:
	GameState.freeze_enemies_for(4.0)
	_aoe_damage(player.global_position, 100.0, 60, Color("#00e5ff"))


## Cavaleiro — empurra todos os inimigos pra fora + 2.5s invul no player.
func _special_shield_bash(player: Player) -> void:
	player.add_invulnerability(2.5)
	for e in player.get_tree().get_nodes_in_group("enemies"):
		if not (e is Enemy):
			continue
		var enemy := e as Enemy
		var to_enemy: Vector2 = enemy.global_position - player.global_position
		if to_enemy.length() < 1.0:
			continue
		# Knockback radial forte
		enemy.global_position += to_enemy.normalized() * 80.0


## Punk — dispara 16 projéteis em todas direções.
func _special_rage_burst(player: Player) -> void:
	var count := 16
	for i in count:
		var angle: float = TAU * float(i) / float(count)
		var dir := Vector2(cos(angle), sin(angle))
		var proj := Projectile.new()
		proj.tint = Color("#e91e63")
		proj.crit_chance = player.crit_chance
		proj.crit_mult = player.crit_mult
		proj.setup(player.global_position, dir, 24, 280.0, 1)  ## pierce 1
		player.get_parent().add_child(proj)


## Ninja — teleporta pro inimigo mais próximo + AoE dano grande.
func _special_shadow_strike(player: Player) -> void:
	var target := player.find_nearest_enemy(400.0)
	if target != null:
		player.global_position = target.global_position - Vector2(20, 0)
	player.add_invulnerability(0.6)
	_aoe_damage(player.global_position, 120.0, 100, Color("#b71c1c"))


## Cyborg — cartuchos disparam 3x mais rápido por 6s. Implementado via
## damage_mult temporário porque o spawn rate dos cartuchos é interno.
## Pra v1: dano massivo + freeze 2s pra simular "overload" — refinar depois.
func _special_overload(player: Player) -> void:
	GameState.freeze_enemies_for(2.0)
	_aoe_damage(player.global_position, 140.0, 80, Color("#00e676"))


## Hacker — invuln 4s + congela tudo.
func _special_debug_mode(player: Player) -> void:
	player.add_invulnerability(4.0)
	GameState.freeze_enemies_for(4.0)


## Gamer Retrô (Chubby) — nuke: dano massivo em todos inimigos visíveis.
func _special_nuke(player: Player) -> void:
	_aoe_damage(player.global_position, 9999.0, 150, Color("#ef5350"))


## Mago — explosão mágica em ondas concêntricas (2 hits em raios diferentes).
func _special_arcane_nova(player: Player) -> void:
	_aoe_damage(player.global_position, 80.0, 80, Color("#7e57c2"))
	# Segundo pulso atrasado, raio maior, dano menor
	var center := player.global_position
	var t := player.get_tree().create_timer(0.35, true, false, true)
	await t.timeout
	if is_instance_valid(player):
		_aoe_damage(center, 160.0, 50, Color("#b39ddb"))


## Pixel Ghost — 5s invuln + lifesteal.
func _special_phase_out(player: Player) -> void:
	player.add_invulnerability(5.0)


## Helper: aplica dano em todos os inimigos dentro do raio. Spawna spark visual.
func _aoe_damage(center: Vector2, radius: float, damage: int, color: Color) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Enemy):
			continue
		var enemy := e as Enemy
		if enemy.global_position.distance_to(center) <= radius:
			enemy.take_damage(damage, Vector2.ZERO, false)
	# Spark visual no centro
	var spark := HitSpark.new()
	var arena: Node = tree.current_scene
	if arena != null:
		arena.add_child(spark)
		spark.setup(center, color)
