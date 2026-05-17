## Z-Buffer — mini-boss da Era 64-bit. Dispara TRIÂNGULOS em formação cone
## sempre na direção do player. HP maior que Sentinel mas ataques previsíveis —
## quem se move bem evita.
class_name MiniBossZBuffer
extends MiniBoss

const CONE_INTERVAL := 3.0
const CONE_PROJECTILES := 3
const CONE_SPREAD := PI * 0.22  ## ~40°
const CONE_SPEED := 145.0
const CONE_DAMAGE := 11

const TINT_Z := Color("#7e57c2")

var _cone_timer: float = 1.5


func _init() -> void:
	super()
	max_hp = 320
	move_speed = 32.0  ## mais lento (tank pesado)
	contact_damage = 28
	death_color = TINT_Z
	_ring_timer = 999.0  ## desabilita ring herdado


func _build_visual() -> void:
	super()
	if sprite != null:
		sprite.modulate = TINT_Z
		sprite.scale = Vector2(sprite_scale * 1.15, sprite_scale * 1.15)  ## maior


func _physics_process(delta: float) -> void:
	_chase_player(delta)
	_update_flash(delta)
	move_and_slide()
	if not GameState.run_active or is_queued_for_deletion():
		return
	_cone_timer -= delta
	if _cone_timer <= 0.0:
		_cone_timer = CONE_INTERVAL
		_fire_cone()


func _fire_cone() -> void:
	var player := _find_player()
	if player == null:
		return
	var base_dir := (player.global_position - global_position).normalized()
	for i in CONE_PROJECTILES:
		var offset_idx: float = float(i) - float(CONE_PROJECTILES - 1) * 0.5
		var angle: float = base_dir.angle() + offset_idx * (CONE_SPREAD / float(CONE_PROJECTILES - 1))
		var dir := Vector2(cos(angle), sin(angle))
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, CONE_DAMAGE, CONE_SPEED)
		get_parent().add_child(proj)
