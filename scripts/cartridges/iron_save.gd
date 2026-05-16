## Iron Save — evolução de Save State + Power Glove.
## Concede 2 revives (50% HP cada) + +60% dano permanente após primeiro uso.
extends CartridgeBase

const DAMAGE_BOOST := 0.6

var _granted_revives: int = 0
var _revives_at_setup: int = 0
var _boost_applied: bool = false


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
	_granted_revives = level + 1  # nível 1 = 2 revives, level 2 = 3, etc
	player.save_state_revives += _granted_revives
	_revives_at_setup = player.save_state_revives


func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	# Detecta primeiro uso de revive → aplica boost permanente
	if not _boost_applied and player.save_state_revives < _revives_at_setup:
		_boost_applied = true
		player.damage_mult += DAMAGE_BOOST
