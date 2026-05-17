## Player — Spirit "Pixel".
## CharacterBody2D criado programaticamente. Não precisa de .tscn.
class_name Player
extends CharacterBody2D

const HURT_INVUL_TIME := 0.5
const HURT_FLASH_TIME := 0.18
const HURTBOX_RADIUS := 8.0
const BODY_RADIUS := 6.0
const DEFAULT_SPRITE_SCALE := 2.0

const DASH_SPEED := 480.0
const DASH_DURATION := 0.15

const KNOCKBACK_FORCE := 260.0
const KNOCKBACK_DURATION := 0.14

# Trail/afterimage durante o dash: cópia do sprite atual com fade, espaçada no tempo.
const DASH_TRAIL_INTERVAL := 0.03
const DASH_TRAIL_LIFETIME := 0.35
const DASH_TRAIL_COLOR := Color("#64b5f6")

# Tiers de evolução visual do GAMO. Trocas em level-up de acordo com EVOLUTION_THRESHOLDS:
#   tier 1 (sem armadura) → tier 2 (armadura leve) → tier 3 (armadura pesada)
const EVOLUTION_THRESHOLDS := [5, 10]
const WEAPON_OFFSET := 14.0          # distância da arma ao centro do player (em px-mundo)
const WEAPON_AIM_RADIUS := 480.0

@export var max_hp: int = 100
@export var move_speed: float = 150.0

var sprite_scale_value: float = DEFAULT_SPRITE_SCALE
var dash_max_cooldown: float = 4.0
var spirit_palette: Dictionary = Sprites.PALETTE_GAMO
var spirit_frames: Array = Sprites.GAMO_T1_IDLE
var starting_cartridge: String = "star_blaster"

var current_hp: int
var equipped_cartridges: Dictionary = {}  # cartridge_id (String) -> level (int)
var damage_mult: float = 1.0
var pickup_radius_mult: float = 1.0
var save_state_revives: int = 0  # Save State — revive com 50% HP
var reset_button_revives: int = 0  # Reset Button (boss legendary) — revive full HP
# Crit base. Pode ser bumpado por upgrades/cartuchos no futuro.
var crit_chance: float = 0.08
var crit_mult: float = 2.0

var sprite: AnimatedSprite2D
var weapon_sprite: Sprite2D
var hurtbox: Area2D
var cartridge_root: Node

var current_tier: int = 1
var projectile_tint: Color = Color.WHITE

var _invul_timer: float = 0.0
var _hurt_flash_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0
var _knockback_dir: Vector2 = Vector2.ZERO
var _facing: int = 1
var _walk_phase: float = 0.0  # avança quando o player está se movendo
var _trail_timer: float = 0.0
var _dying: bool = false  # bloqueia input/dano enquanto a morte cinemática roda


func _ready() -> void:
	current_hp = max_hp
	add_to_group("player")
	collision_layer = 2  # player body
	collision_mask = 0   # não colide com nada via física

	_build_collision_shape()
	_build_sprite()
	_build_weapon_sprite()
	_build_hurtbox()
	_build_cartridge_root()
	EventBus.player_leveled_up.connect(_on_level_up_visual)


func _build_collision_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BODY_RADIUS
	shape.shape = circle
	add_child(shape)


func _build_sprite() -> void:
	# Aplica skin escolhida na hub — fallback pra paleta default se a skin
	# não estiver no registry por algum motivo.
	var skin_palette: Dictionary = SkinRegistry.active_palette()
	spirit_palette = skin_palette
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		spirit_frames, spirit_palette, 3.0
	)
	sprite.play("default")
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale_value, sprite_scale_value)
	add_child(sprite)


func _build_weapon_sprite() -> void:
	weapon_sprite = Sprite2D.new()
	weapon_sprite.texture = Sprites.weapon_blaster
	weapon_sprite.centered = true
	weapon_sprite.scale = Vector2(sprite_scale_value, sprite_scale_value)
	weapon_sprite.position = Vector2(WEAPON_OFFSET, 0)
	# Pintura amarela default — combina com o projétil padrão.
	weapon_sprite.modulate = Color.WHITE
	# Renderiza por cima do corpo do player para a arma não ser escondida.
	weapon_sprite.z_index = 1
	add_child(weapon_sprite)


## Substitui a textura da arma visível e o tint dos projéteis disparados pelo player.
## Chamado por cada cartucho-arma no setup/on_level_up.
func set_weapon_visual(texture: ImageTexture, p_tint: Color = Color.WHITE) -> void:
	if texture != null and weapon_sprite != null:
		weapon_sprite.texture = texture
	projectile_tint = p_tint


func _build_hurtbox() -> void:
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 8  # detecta corpos de inimigo (layer 4 = bit 3 = valor 8)
	hurtbox.monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = HURTBOX_RADIUS
	shape.shape = circle
	hurtbox.add_child(shape)
	add_child(hurtbox)


func _build_cartridge_root() -> void:
	cartridge_root = Node.new()
	cartridge_root.name = "CartridgeRoot"
	add_child(cartridge_root)


func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_update_timers(delta)
	_update_flicker()
	_update_weapon_aim()
	_update_walk_animation(delta)
	_update_dash_trail(delta)
	move_and_slide()
	_clamp_to_arena()
	_check_enemy_contact()


## Spawna afterimages do sprite atual durante o dash — efeito clássico de speedster.
## Também spawna um trail sutil (menos frequente, mais transparente) quando o
## player tá se movendo em velocidade alta — feel de "deixando rastro pixelado".
func _update_dash_trail(delta: float) -> void:
	if sprite == null:
		return
	# Dash: afterimage intenso azul a cada 0.03s.
	if _dash_timer > 0.0:
		_trail_timer -= delta
		if _trail_timer > 0.0:
			return
		_trail_timer = DASH_TRAIL_INTERVAL
		_spawn_afterimage(DASH_TRAIL_COLOR, DASH_TRAIL_LIFETIME, 0.6)
		return
	# Walk trail: afterimage sutil branco a cada 0.08s quando se movendo rápido.
	# Só faz se a velocidade efetiva for considerável (não conta knockback).
	if velocity.length_squared() > 12000.0:  # ~110 px/s
		_trail_timer -= delta
		if _trail_timer > 0.0:
			return
		_trail_timer = 0.08
		_spawn_afterimage(Color(1.0, 1.0, 1.0, 0.35), 0.18, 0.85)
	else:
		_trail_timer = 0.0


func _spawn_afterimage(tint: Color, lifetime: float, end_scale_mult: float) -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.sprite_frames.get_frame_texture("default", sprite.frame)
	ghost.centered = true
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.global_position = global_position
	ghost.modulate = tint
	ghost.z_index = z_index - 1
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, lifetime)
	tween.parallel().tween_property(ghost, "scale", sprite.scale * end_scale_mult, lifetime)
	tween.tween_callback(ghost.queue_free)


## Bob vertical + leve inclinação lateral quando o player está se movendo —
## dá a sensação de "flutuar/caminhar" mesmo sem frames de animação dedicados.
func _update_walk_animation(delta: float) -> void:
	if sprite == null:
		return
	var speed_sq: float = velocity.length_squared()
	if speed_sq > 100.0:  # threshold pra considerar "andando"
		_walk_phase += delta * 12.0
		sprite.position.y = sin(_walk_phase) * 1.5
		sprite.rotation = sin(_walk_phase * 0.5) * 0.06  # ~3.5°
	else:
		# Idle: bob suave constante (efeito flutuando)
		_walk_phase += delta * 2.0
		sprite.position.y = sin(_walk_phase) * 0.6
		sprite.rotation = lerpf(sprite.rotation, 0.0, delta * 8.0)


## Mira a arma no inimigo mais próximo (orbitando o player), ou aponta na direção
## de movimento/facing quando não há alvo. Mantém o player com cara de "armado".
func _update_weapon_aim() -> void:
	if weapon_sprite == null:
		return
	var enemy := find_nearest_enemy(WEAPON_AIM_RADIUS)
	var dir: Vector2
	if enemy != null:
		dir = (enemy.global_position - global_position)
	else:
		dir = Vector2(float(_facing), 0.0)
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	weapon_sprite.position = dir * WEAPON_OFFSET
	weapon_sprite.rotation = dir.angle()
	# Quando aponta pra esquerda, espelha verticalmente para o cano não ficar de cabeça pra baixo.
	weapon_sprite.flip_v = dir.x < 0


## Reage ao signal player_leveled_up trocando a sprite do GAMO quando cruza
## um limiar de evolução (sem armadura → leve → pesada).
func _on_level_up_visual(new_level: int) -> void:
	var target_tier := 1
	if new_level >= EVOLUTION_THRESHOLDS[1]:
		target_tier = 3
	elif new_level >= EVOLUTION_THRESHOLDS[0]:
		target_tier = 2
	if target_tier == current_tier:
		return
	current_tier = target_tier
	var frames: Array
	match target_tier:
		2:
			frames = Sprites.GAMO_T2_IDLE
		3:
			frames = Sprites.GAMO_T3_IDLE
		_:
			frames = Sprites.GAMO_T1_IDLE
	# Mantém a paleta da skin ativa em todos os tiers de evolução.
	sprite.sprite_frames = Sprites.make_animation(frames, SkinRegistry.active_palette(), 3.0)
	sprite.play("default")


func _handle_input(delta: float) -> void:
	if _knockback_timer > 0.0:
		velocity = _knockback_dir * KNOCKBACK_FORCE
		return
	if _dash_timer > 0.0:
		velocity = _dash_dir * DASH_SPEED
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * move_speed

	if input.x < -0.1:
		_facing = -1
	elif input.x > 0.1:
		_facing = 1
	if sprite != null:
		sprite.flip_h = _facing < 0

	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0:
		_start_dash(input)


func _start_dash(input: Vector2) -> void:
	var dir := input
	if dir.length_squared() < 0.01:
		dir = Vector2(_facing, 0)
	_dash_dir = dir.normalized()
	_dash_timer = DASH_DURATION
	_dash_cooldown_timer = dash_max_cooldown
	_invul_timer = max(_invul_timer, DASH_DURATION + 0.1)
	Audio.play(Audio.Sfx.DASH)


## Aplica config de Spirit antes do _ready (chamar antes de add_child).
func apply_spirit(def: SpiritRegistry.SpiritDef) -> void:
	if def == null:
		return
	max_hp = def.base_hp
	move_speed = def.base_speed
	sprite_scale_value = def.sprite_scale
	dash_max_cooldown = def.dash_max_cooldown
	spirit_palette = def.palette
	spirit_frames = def.sprite_frames
	starting_cartridge = def.starting_cartridge


func _update_timers(delta: float) -> void:
	if _invul_timer > 0.0:
		_invul_timer -= delta
	if _hurt_flash_timer > 0.0:
		_hurt_flash_timer -= delta
	if _knockback_timer > 0.0:
		_knockback_timer -= delta
	if _dash_timer > 0.0:
		_dash_timer -= delta
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta


func _update_flicker() -> void:
	if sprite == null:
		return
	if _hurt_flash_timer > 0.0:
		# Flash de dano: clarão vermelho saturado por ~0.18s.
		var f: float = _hurt_flash_timer / HURT_FLASH_TIME
		sprite.modulate = Color(2.5, 0.4 + (1.0 - f) * 0.6, 0.4 + (1.0 - f) * 0.6, 1.0)
	elif _invul_timer > 0.0:
		var t: float = float(Time.get_ticks_msec()) * 0.04
		var alpha: float = 0.4 + 0.5 * absf(sin(t))
		sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	else:
		sprite.modulate = Color.WHITE


func _clamp_to_arena() -> void:
	var rect: Rect2 = ArenaBounds.get_rect()
	if rect.size == Vector2.ZERO:
		return
	position.x = clampf(position.x, rect.position.x + 8, rect.end.x - 8)
	position.y = clampf(position.y, rect.position.y + 8, rect.end.y - 8)


func _check_enemy_contact() -> void:
	if _invul_timer > 0.0 or hurtbox == null:
		return
	for body in hurtbox.get_overlapping_bodies():
		if body is Enemy:
			var enemy := body as Enemy
			var dir := global_position - enemy.global_position
			take_damage(enemy.contact_damage, dir)
			return  # uma hit por ciclo (próxima respeitará invul)


func take_damage(amount: int, knockback_source_dir: Vector2 = Vector2.ZERO) -> void:
	if _invul_timer > 0.0:
		return
	# Filtra pelo BoonSystem (IRON_SKIN reduz dano em 50% se ativo).
	amount = BoonSystem.filter_damage(amount)
	if amount <= 0:
		return
	current_hp = max(0, current_hp - amount)
	_invul_timer = HURT_INVUL_TIME
	_hurt_flash_timer = HURT_FLASH_TIME
	if knockback_source_dir.length_squared() > 0.01:
		_knockback_dir = knockback_source_dir.normalized()
		_knockback_timer = KNOCKBACK_DURATION
	Audio.play(Audio.Sfx.PLAYER_HURT)
	_spawn_hurt_number(amount)
	EventBus.player_damaged.emit(amount, current_hp, max_hp)
	if current_hp <= 0:
		_die()


func _spawn_hurt_number(amount: int) -> void:
	if amount <= 0:
		return
	var dn := DamageNumber.new()
	dn.global_position = global_position + Vector2(
		randf_range(-6.0, 6.0), -14.0 + randf_range(-4.0, 4.0)
	)
	dn.setup(amount, false, DamageNumber.Kind.PLAYER_HURT)
	get_parent().add_child(dn)


func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	EventBus.player_healed.emit(amount, current_hp, max_hp)


func _die() -> void:
	if reset_button_revives > 0:
		reset_button_revives -= 1
		current_hp = max_hp
		_invul_timer = 2.0
		EventBus.player_healed.emit(current_hp, current_hp, max_hp)
		return
	if save_state_revives > 0:
		save_state_revives -= 1
		current_hp = max(max_hp / 2, 1)
		_invul_timer = 2.0
		EventBus.player_healed.emit(current_hp, current_hp, max_hp)
		return
	_start_death_sequence()


## Sequência cinemática de morte: freeze, explosões em cascata, sprite enche/fade,
## shake, vinheta escura, texto "GLITCH PREVAILS" entrando com bounce.
## Após ~2.2s, emite player_died pra arena finalizar a run.
func _start_death_sequence() -> void:
	if _dying:
		return
	_dying = true
	_invul_timer = 9999.0
	velocity = Vector2.ZERO
	set_physics_process(false)
	# Desliga os cartuchos (não dispara mais nada durante a cinematics).
	if cartridge_root != null:
		cartridge_root.process_mode = Node.PROCESS_MODE_DISABLED
	if weapon_sprite != null:
		weapon_sprite.visible = false

	HitStop.freeze(0.15)
	Audio.play(Audio.Sfx.PLAYER_HURT)
	Audio.play(Audio.Sfx.ENEMY_DIE)
	Music.stop()

	# 6 ondas de partículas escalonadas em torno do player.
	for wave in 6:
		var delay: float = float(wave) * 0.12
		var t := get_tree().create_timer(delay, true, false, true)
		t.timeout.connect(_spawn_death_burst)

	# Animação do sprite: vermelho intenso → branco ofuscado → fade transparente.
	if sprite != null:
		var color_tween := create_tween()
		color_tween.set_ignore_time_scale(true)
		color_tween.tween_property(sprite, "modulate", Color(3.0, 0.4, 0.4, 1.0), 0.15)
		color_tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.20)
		color_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.55)
		# Scale up junto pra dar peso.
		var scale_tween := create_tween()
		scale_tween.set_ignore_time_scale(true)
		scale_tween.tween_property(sprite, "scale", sprite.scale * 1.7, 0.85) \
			.set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_CUBIC)

	# Shake forte via arena.
	_trigger_death_shake()
	# Overlay com vinheta + "GLITCH PREVAILS".
	_build_death_overlay()
	# Após 2.2s, sinaliza a arena pra avançar pro game-over.
	get_tree().create_timer(2.2, true, false, true).timeout.connect(_finalize_death)


func _spawn_death_burst() -> void:
	if not is_instance_valid(get_parent()):
		return
	var dp := DeathParticle.new()
	dp.global_position = global_position + Vector2(
		randf_range(-16.0, 16.0), randf_range(-16.0, 16.0)
	)
	# Mistura de cores quentes (vermelho/amarelo) + flash magenta ocasional.
	var col: Color = Color("#ff5252")
	var roll: float = randf()
	if roll > 0.7:
		col = Color("#ffeb3b")
	elif roll > 0.9:
		col = Color("#e040fb")
	dp.setup(col)
	get_parent().add_child(dp)


func _trigger_death_shake() -> void:
	# Sobe na árvore até achar o nó com trigger_shake (arena).
	var n: Node = get_parent()
	while n != null and not n.has_method("trigger_shake"):
		n = n.get_parent()
	if n != null:
		n.call("trigger_shake", 10.0, 1.0)


func _build_death_overlay() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 9
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	scene_root.add_child(layer)

	# Vinheta escurecendo a tela
	var vignette := ColorRect.new()
	vignette.color = Color(0, 0, 0, 0)
	vignette.anchor_right = 1.0
	vignette.anchor_bottom = 1.0
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vignette)
	var v_tween := vignette.create_tween()
	v_tween.set_ignore_time_scale(true)
	v_tween.tween_property(vignette, "color:a", 0.62, 1.4) \
		.set_ease(Tween.EASE_IN)

	# Label "GLITCH PREVAILS" gigante entrando com bounce após 0.7s.
	var label := Label.new()
	label.text = "GLITCH PREVAILS"
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color("#ff0080"))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.5
	label.position = Vector2(-280, -40)
	label.size = Vector2(560, 64)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.pivot_offset = Vector2(280, 32)
	label.scale = Vector2(0.1, 0.1)
	label.modulate = Color(1, 1, 1, 0)
	layer.add_child(label)
	var l_tween := label.create_tween().set_parallel(true)
	l_tween.set_ignore_time_scale(true)
	l_tween.tween_property(label, "scale", Vector2.ONE, 0.5) \
		.set_delay(0.7) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	l_tween.tween_property(label, "modulate:a", 1.0, 0.4) \
		.set_delay(0.7)


func _finalize_death() -> void:
	EventBus.player_died.emit()


## Calcula dano final aplicando rolagem de crítico. Retorna [amount, is_crit].
## Usado por cartuchos de dano direto (orbitais) que não passam por Projectile.
func roll_damage(base: int) -> Array:
	var is_crit: bool = randf() < crit_chance
	var amount: int = int(round(float(base) * (crit_mult if is_crit else 1.0)))
	return [amount, is_crit]


## Encontra o inimigo mais próximo dentro de um raio. null se nenhum.
func find_nearest_enemy(max_distance: float = 9999.0) -> Enemy:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Enemy = null
	var nearest_d := max_distance
	for e in enemies:
		if not (e is Enemy):
			continue
		var d := global_position.distance_to((e as Enemy).global_position)
		if d < nearest_d:
			nearest_d = d
			nearest = e
	return nearest


func equip_cartridge(cartridge_id: String) -> void:
	var def: CartridgeRegistry.CartridgeDef = CartridgeRegistry.get_def(cartridge_id)
	if def == null:
		push_warning("Cartucho desconhecido: %s" % cartridge_id)
		return
	var current_level: int = equipped_cartridges.get(cartridge_id, 0)
	if current_level >= def.max_level:
		return
	equipped_cartridges[cartridge_id] = current_level + 1

	if current_level == 0:
		_instantiate_cartridge(def)
	else:
		_level_up_cartridge(cartridge_id, current_level + 1)
	EventBus.cartridge_equipped.emit(cartridge_id)


func _instantiate_cartridge(def: CartridgeRegistry.CartridgeDef) -> void:
	var script: Script = load(def.script_path)
	if script == null:
		push_warning("Script não encontrado: %s" % def.script_path)
		return
	var node: Node = script.new()
	node.name = def.id
	if node.has_method("setup"):
		node.call("setup", self, 1)
	cartridge_root.add_child(node)


func _level_up_cartridge(cartridge_id: String, new_level: int) -> void:
	var node := cartridge_root.get_node_or_null(cartridge_id)
	if node == null:
		return
	if node.has_method("on_level_up"):
		node.call("on_level_up", new_level)


## Remove um cartucho do player. Reverte efeitos passivos via on_unequip().
func unequip_cartridge(cartridge_id: String) -> void:
	if not equipped_cartridges.has(cartridge_id):
		return
	equipped_cartridges.erase(cartridge_id)
	var node := cartridge_root.get_node_or_null(cartridge_id)
	if node == null:
		return
	if node.has_method("on_unequip"):
		node.call("on_unequip")
	node.queue_free()
