## Disc Reader — mini-boss da Era 32-bit CD. Em vez do ring radial do Sentinel,
## dispara 4 lasers que rotacionam ao redor dele, criando padrão de helicópteros.
## HP igual, mas ataque mais sustained — exige movimento orbital pra evitar.
class_name MiniBossDiscReader
extends MiniBoss

const LASER_INTERVAL := 5.2  ## tempo entre cada burst de lasers
const LASER_COUNT := 4
const LASER_SPEED := 110.0
const LASER_DAMAGE := 8
const LASER_ROT_OFFSET := PI * 0.5  ## offset de rotação no burst

const TINT_DISC := Color("#00e5ff")

var _disc_timer: float = 1.8
var _rotation_phase: float = 0.0


func _init() -> void:
	super()
	max_hp = 260
	move_speed = 35.0  ## um pouco mais lento que Sentinel
	death_color = TINT_DISC
	_ring_timer = 999.0  ## desabilita o ring radial herdado (não usa)


func _build_visual() -> void:
	super()
	if sprite != null:
		sprite.modulate = TINT_DISC


func _physics_process(delta: float) -> void:
	# Não chama super._physics_process pra evitar disparar o ring herdado.
	# Replica a lógica essencial de Enemy + ataque próprio do Disc Reader.
	_chase_player(delta)
	_update_flash(delta)
	move_and_slide()
	if not GameState.run_active or is_queued_for_deletion():
		return
	_rotation_phase += delta * 0.6
	_disc_timer -= delta
	if _disc_timer <= 0.0:
		_disc_timer = LASER_INTERVAL
		_fire_lasers()


## 4 lasers saindo em padrão de helicóptero, com offset de fase rotativo.
func _fire_lasers() -> void:
	for i in LASER_COUNT:
		var base_angle: float = TAU * float(i) / float(LASER_COUNT)
		var angle: float = base_angle + _rotation_phase
		var dir := Vector2(cos(angle), sin(angle))
		var proj := EnemyProjectile.new()
		proj.setup(global_position, dir, LASER_DAMAGE, LASER_SPEED)
		get_parent().add_child(proj)
