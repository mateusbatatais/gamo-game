## Classe base de inimigo (Glitch).
## Cada variação (Artifact, Tear, Null) estende esta e sobrescreve _build_visual + comportamento.
class_name Enemy
extends CharacterBody2D

@export var max_hp: int = 10
@export var contact_damage: int = 5
@export var move_speed: float = 56.0
@export var xp_value: int = 1
@export var token_value: int = 1
@export var body_radius: float = 6.0
@export var sprite_scale: float = 2.0
## Cor base usada pra explosão de partículas ao morrer. Inimigos podem sobrescrever
## no _ready/_build_visual chamando set_death_color() pra combinar com a paleta deles.
@export var death_color: Color = Color("#9bbc0f")
## Chance (0..1) de dropar pickup de vida ao morrer. Stains/projéteis-living deixam em 0.
@export var health_drop_chance: float = 0.05
## Chance (0..1) de dropar power-up raro ao morrer. Aprox 1 a cada 130 kills.
@export var power_up_drop_chance: float = 0.008

var current_hp: int
var sprite: AnimatedSprite2D
var _flash_timer: float = 0.0
var _dying_anim: bool = false


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 1  # apenas world; player é detectado via Area2D hurtbox
	# Prestige scaling: +15% HP/dmg + 25% tokens por nível NG+ (cap 5).
	var p_mult: float = 1.0 + GameState.prestige_level * 0.15
	max_hp = int(max(1, round(max_hp * p_mult)))
	contact_damage = int(max(1, round(contact_damage * p_mult)))
	token_value = int(max(1, round(token_value * (1.0 + GameState.prestige_level * 0.25))))
	current_hp = max_hp
	_build_shape()
	_build_visual()
	# Registra encontro no codex (id derivado do class_name).
	var codex_id: String = _codex_id()
	if codex_id != "":
		GameState.register_encounter(codex_id)
	EventBus.enemy_spawned.emit(self)


## Cada subclasse pode sobrescrever pra mapear pro id do codex.
## Por default usa get_script().get_global_name() em snake_case.
func _codex_id() -> String:
	# Object.get_script() retorna Variant (qualquer Resource), por isso o tipo explícito.
	var script: Script = get_script() as Script
	if script == null:
		return ""
	var class_id: String = script.get_global_name()
	if class_id == "":
		return ""
	# CamelCase → snake_case (Artifact → artifact, MiniBoss → mini_boss)
	var out: String = ""
	for i in class_id.length():
		var c: String = class_id[i]
		if i > 0 and c.to_upper() == c and c.to_lower() != c:
			out += "_"
		out += c.to_lower()
	return out


func _build_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = body_radius
	shape.shape = circle
	add_child(shape)


## Override por subclasses.
func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	add_child(sprite)


func _physics_process(delta: float) -> void:
	_chase_player(delta)
	_update_flash(delta)
	move_and_slide()


func _chase_player(_delta: float) -> void:
	# Freeze power-up congela todos os inimigos.
	if GameState.is_enemies_frozen():
		velocity = Vector2.ZERO
		return
	var player := _find_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	var dir := (player.global_position - global_position)
	if dir.length_squared() > 0.01:
		velocity = dir.normalized() * move_speed * ModifierSystem.enemy_speed_mult()
	else:
		velocity = Vector2.ZERO


func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node2D


func _update_flash(delta: float) -> void:
	if sprite == null:
		return
	if _flash_timer > 0.0:
		_flash_timer -= delta
		# Photosensitive: reduz flash de 2.5x pra 1.5x (ainda visível, menos agressivo).
		var f: float = 1.5 if Settings.photosensitive_mode else 2.5
		sprite.modulate = Color(f, f, f, 1.0)
	elif GameState.is_enemies_frozen():
		# Tint azul-claro de "congelado" durante o power-up FREEZE.
		sprite.modulate = Color(0.55, 0.85, 1.6, 1.0)
	else:
		sprite.modulate = Color.WHITE


## take_damage agora aceita parâmetros opcionais para knockback (não usado pelos
## inimigos comuns) e flag de crit pra cor/tamanho diferente do damage number.
func take_damage(amount: int, _knockback_dir: Vector2 = Vector2.ZERO, is_crit: bool = false) -> void:
	var dealt: int = min(current_hp, amount)
	current_hp -= amount
	GameState.register_damage_dealt(dealt)
	_flash_timer = 0.10 if is_crit else 0.06
	_spawn_damage_number(amount, is_crit)
	# Crits dão hit-stop curto + screen flash pra dar peso ao impacto.
	if is_crit:
		HitStop.freeze()
		CritFlash.flash()
	if current_hp <= 0:
		_die()


func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	if amount <= 0:
		return
	var dn := DamageNumber.new()
	# Offset aleatório pequeno pra números não se sobreporem quando vários hits caem juntos.
	dn.global_position = global_position + Vector2(
		randf_range(-4.0, 4.0), -8.0 + randf_range(-4.0, 4.0)
	)
	dn.setup(amount, is_crit)
	get_parent().add_child(dn)


func _die() -> void:
	if _dying_anim:
		return
	_dying_anim = true
	Audio.play(Audio.Sfx.ENEMY_DIE)
	GameState.register_kill()
	GameState.grant_tokens(token_value)
	EventBus.enemy_killed.emit(self, xp_value)
	# Desativa colisão pra não tomar mais hits durante a anim.
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	# Sink animation: sprite encolhe + escurece em ~120ms antes de explodir.
	if sprite != null:
		var tween := sprite.create_tween().set_parallel(true)
		tween.tween_property(sprite, "scale", sprite.scale * 0.35, 0.12)
		tween.tween_property(sprite, "modulate", Color(0.4, 0.1, 0.1, 0.5), 0.12)
	# Aguarda a anim terminar antes da explosão + drops + free.
	await get_tree().create_timer(0.11, true).timeout
	_spawn_death_particles()
	_drop_xp_gem()
	_maybe_drop_health()
	_maybe_drop_power_up()
	queue_free()


func _drop_xp_gem() -> void:
	var gem := XpGem.new()
	gem.value = xp_value
	gem.global_position = global_position
	get_parent().add_child(gem)


func _spawn_death_particles() -> void:
	# 3 bursts em posições levemente offset criam impressão de "explosão" maior.
	# Cores variando do death_color base → branco brilhante no centro.
	for i in 3:
		var p := DeathParticle.new()
		p.global_position = global_position + Vector2(
			randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)
		)
		# Burst central mais brilhante, outros com cor base.
		var burst_color: Color = death_color
		if i == 0:
			burst_color = Color(
				min(1.0, death_color.r + 0.3),
				min(1.0, death_color.g + 0.3),
				min(1.0, death_color.b + 0.3),
				1.0
			)
		p.setup(burst_color)
		get_parent().add_child(p)
	# Hit spark adicional pra "flash" de impacto.
	var spark := HitSpark.new()
	get_parent().add_child(spark)
	spark.setup(global_position, death_color)


func _maybe_drop_health() -> void:
	if health_drop_chance <= 0.0:
		return
	if randf() > health_drop_chance:
		return
	var pickup := HealthPickup.new()
	pickup.global_position = global_position
	get_parent().add_child(pickup)


func _maybe_drop_power_up() -> void:
	if power_up_drop_chance <= 0.0:
		return
	# Lucky Chip talent adiciona absoluto na chance.
	var chance: float = power_up_drop_chance + TalentTree.power_up_drop_bonus()
	if randf() > chance:
		return
	var p := PowerUp.new()
	# Sorteia entre os 3 tipos de power-up.
	p.kind = randi() % 3
	p.global_position = global_position
	get_parent().add_child(p)
