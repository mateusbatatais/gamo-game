## Projétil disparado por inimigos (Checksum, Boss).
## Causa dano ao player on contact.
class_name EnemyProjectile
extends Area2D

const DEFAULT_LIFETIME := 4.0
const SPRITE_SCALE := 2.0

var speed: float = 100.0
var damage: int = 5
var direction: Vector2 = Vector2.RIGHT
var _age: float = 0.0
var _lifetime: float = DEFAULT_LIFETIME

var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 128  # projectile_enemy
	collision_mask = 4     # player_hitbox (layer 3 = bit 2 = valor 4)
	monitoring = true
	monitorable = true
	_build_visual()
	_build_shape()
	area_entered.connect(_on_area_entered)


func _build_visual() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = Sprites.boss_projectile
	_sprite.centered = true
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	add_child(_sprite)


func _build_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)


func setup(start_pos: Vector2, dir: Vector2, p_damage: int, p_speed: float = 100.0) -> void:
	global_position = start_pos
	direction = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	damage = p_damage
	speed = p_speed
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	# Freeze também segura projéteis inimigos pra parecer "tempo parado".
	if not GameState.is_enemies_frozen():
		position += direction * speed * delta
	_age += delta
	if _age >= _lifetime:
		queue_free()
		return
	if not _inside_play_area():
		queue_free()


func _inside_play_area() -> bool:
	var rect: Rect2 = ArenaBounds.get_rect().grow(32.0)
	return rect.has_point(global_position)


func _on_area_entered(area: Area2D) -> void:
	# area é a hurtbox do player
	var player := area.get_parent()
	if player is Player:
		(player as Player).take_damage(damage, direction)
		queue_free()
