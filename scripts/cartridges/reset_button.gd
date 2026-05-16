## Reset Button — passivo lendário (drop do boss).
## Cura totalmente o player quando ele morreria. 1 uso por level.
extends CartridgeBase

var _granted_full_heals: int = 0


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	_apply()


func on_level_up(new_level: int) -> void:
	super(new_level)
	_apply()


## Reset Button incrementa player.reset_button_revives — revive com 100% HP.
## Diferente do Save State, que revive com 50%.
func _apply() -> void:
	if player == null:
		return
	player.reset_button_revives -= _granted_full_heals
	_granted_full_heals = level
	player.reset_button_revives += _granted_full_heals
