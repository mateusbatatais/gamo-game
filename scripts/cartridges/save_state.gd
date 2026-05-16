## Save State — passivo lendário. +1 revive por nível ao morrer.
extends CartridgeBase

var _granted_revives: int = 0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_apply()


func on_level_up(new_level: int) -> void:
	super(new_level)
	_apply()


func _apply() -> void:
	if player == null:
		return
	player.save_state_revives -= _granted_revives
	_granted_revives = level
	player.save_state_revives += _granted_revives


func on_unequip() -> void:
	if player == null:
		return
	player.save_state_revives -= _granted_revives
	_granted_revives = 0
