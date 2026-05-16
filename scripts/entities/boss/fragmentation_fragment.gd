## Fragmento do boss Fragmentation. Versão pequena e ágil.
class_name FragmentationFragment
extends Enemy


func _init() -> void:
	max_hp = 80
	contact_damage = 12
	move_speed = 70.0
	xp_value = 8
	body_radius = 12.0
	sprite_scale = 2.2


func _ready() -> void:
	super()
	add_to_group("boss_fragments")


func _build_visual() -> void:
	sprite = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.add_frame("default", PixelArt.make_sprite(
		PackedStringArray(Sprites.FRAGMENTATION_FRAGMENT[0]),
		Sprites.PALETTE_FRAGMENTATION
	))
	sprite.sprite_frames = sf
	sprite.centered = true
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.play("default")
	add_child(sprite)


func _die() -> void:
	Audio.play(Audio.Sfx.ENEMY_DIE)
	GameState.register_kill()
	EventBus.enemy_killed.emit(self, xp_value)
	# Drop 2 XP gems
	for i in 2:
		var gem := XpGem.new()
		gem.value = 3
		var angle: float = randf() * TAU
		gem.global_position = global_position + Vector2(cos(angle), sin(angle)) * 10.0
		get_parent().add_child(gem)
	queue_free()
