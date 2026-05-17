## Vampiric — passivo: cura X HP a cada kill (chance escalando por nível).
## Bom em builds que matam rápido. Não cura em hit, só em kill (incentiva combo).
##
## Level escala: chance de proc + amount de cura.
extends CartridgeBase

const TINT := Color("#ff5252")


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	# Não muda visual de arma — é passivo.
	EventBus.enemy_killed.connect(_on_enemy_killed)


func on_unequip() -> void:
	if EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.disconnect(_on_enemy_killed)


func _chance() -> float:
	# nv1 = 8%, nv5 = 30%
	return 0.08 + (level - 1) * 0.055


func _heal_amount() -> int:
	# nv1 = 2, nv5 = 6
	return 2 + (level - 1)


func _on_enemy_killed(_enemy: Node2D, _xp: int) -> void:
	if player == null or not is_instance_valid(player):
		return
	if randf() > _chance():
		return
	player.heal(_heal_amount())
