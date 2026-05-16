## Projétil que acelera de uma velocidade inicial até uma velocidade alvo.
## Usado pelo cartucho lendário Region Free.
class_name AcceleratingProjectile
extends Projectile

var initial_speed: float = 90.0
var target_speed: float = 360.0
var accel_time: float = 0.6


func setup_accel(
	start_pos: Vector2,
	dir: Vector2,
	p_damage: int,
	p_initial_speed: float,
	p_target_speed: float,
	p_accel_time: float,
	p_pierce: int
) -> void:
	setup(start_pos, dir, p_damage, p_initial_speed, p_pierce)
	initial_speed = p_initial_speed
	target_speed = p_target_speed
	accel_time = p_accel_time


func _physics_process(delta: float) -> void:
	if accel_time > 0.0 and speed < target_speed:
		var dv: float = (target_speed - initial_speed) * (delta / accel_time)
		speed = minf(speed + dv, target_speed)
	super(delta)
