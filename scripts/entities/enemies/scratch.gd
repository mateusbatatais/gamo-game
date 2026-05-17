## Scratch (Era 32-bit CD) — risco horizontal estilo CD arranhado.
## Atravessa a arena rapidamente em linha reta, alto dano de contato, baixo HP.
class_name Scratch
extends Enemy

var _direction_x: float = 1.0


func _init() -> void:
	max_hp = 4
	contact_damage = 14
	move_speed = 140.0
	xp_value = 1
	token_value = 1
	body_radius = 5.0
	sprite_scale = 2.0
	death_color = Color("#ffffff")


func _ready() -> void:
	super()
	# Decide direção baseado em qual lado do player ele tá.
	var player := _find_player()
	if player != null:
		_direction_x = 1.0 if global_position.x < player.global_position.x else -1.0


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.make_animation(
		Sprites.SCRATCH_IDLE, Sprites.PALETTE_SCRATCH, 12.0
	)
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


## Override: anda só horizontal, ignora eixo Y.
func _chase_player(_delta: float) -> void:
	if GameState.is_enemies_frozen():
		velocity = Vector2.ZERO
		return
	velocity = Vector2(_direction_x * move_speed, 0.0)
	# Se passou da arena, vira.
	var rect: Rect2 = ArenaBounds.get_rect()
	if global_position.x < rect.position.x - 16:
		_direction_x = 1.0
	elif global_position.x > rect.end.x + 16:
		_direction_x = -1.0
