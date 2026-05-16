## Projétil do jogador. Area2D que viaja em linha reta e dá dano em inimigos.
class_name Projectile
extends Area2D

const DEFAULT_LIFETIME := 2.0
const SPRITE_SCALE := 2.0

var speed: float = 280.0
var damage: int = 10
var direction: Vector2 = Vector2.RIGHT
var pierce_left: int = 0
var bounce_left: int = 0
var tint: Color = Color.WHITE
# Crit stats — preenchidos pelo cartucho com base no player no momento do disparo.
var crit_chance: float = 0.08
var crit_mult: float = 2.0
var _age: float = 0.0
var _lifetime: float = DEFAULT_LIFETIME

var _sprite: Sprite2D
var _hits: Array = []


func _ready() -> void:
	collision_layer = 64  # projectile_player
	collision_mask = 8    # enemies layer
	_build_visual()
	_build_shape()
	body_entered.connect(_on_body_entered)


func _build_visual() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = Sprites.projectile
	_sprite.centered = true
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.modulate = tint
	add_child(_sprite)


## Permite trocar o tint depois do _ready (usado por algumas armas que setam
## a cor antes de adicionar o nó à cena).
func set_tint(p_tint: Color) -> void:
	tint = p_tint
	if _sprite != null:
		_sprite.modulate = p_tint


func _build_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)


func setup(start_pos: Vector2, dir: Vector2, p_damage: int, p_speed: float = 280.0, p_pierce: int = 0) -> void:
	global_position = start_pos
	direction = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	damage = p_damage
	speed = p_speed
	pierce_left = p_pierce
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_age += delta
	if _age >= _lifetime:
		queue_free()
		return
	if not _inside_play_area():
		_try_bounce()


func _inside_play_area() -> bool:
	var rect: Rect2 = ArenaBounds.get_rect().grow(32.0)
	return rect.has_point(global_position)


func _try_bounce() -> void:
	if bounce_left <= 0:
		queue_free()
		return
	bounce_left -= 1
	var rect: Rect2 = ArenaBounds.get_rect()
	if global_position.x < rect.position.x or global_position.x > rect.end.x:
		direction.x = -direction.x
	if global_position.y < rect.position.y or global_position.y > rect.end.y:
		direction.y = -direction.y
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if body in _hits:
		return
	if not (body is Enemy):
		return
	_hits.append(body)
	# Cada hit rola crit independente — dá sensação de "estouros" aleatórios.
	var is_crit: bool = randf() < crit_chance
	var final_dmg: int = int(round(float(damage) * (crit_mult if is_crit else 1.0)))
	(body as Enemy).take_damage(final_dmg, Vector2.ZERO, is_crit)
	Audio.play(Audio.Sfx.HIT)
	if pierce_left > 0:
		pierce_left -= 1
	else:
		queue_free()
