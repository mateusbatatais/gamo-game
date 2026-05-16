## Power Glove — passivo. +25% de dano por nível.
extends CartridgeBase

const DAMAGE_PER_LEVEL := 0.25

var _applied_bonus: float = 0.0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_apply()


func on_level_up(new_level: int) -> void:
	super(new_level)
	_apply()


func _apply() -> void:
	# Remove o bônus anterior e re-aplica baseado no level atual
	if player == null:
		return
	player.damage_mult -= _applied_bonus
	_applied_bonus = DAMAGE_PER_LEVEL * float(level)
	player.damage_mult += _applied_bonus


func on_unequip() -> void:
	if player == null:
		return
	player.damage_mult -= _applied_bonus
	_applied_bonus = 0.0
