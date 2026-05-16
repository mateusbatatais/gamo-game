## Classe-base de cartucho. Cada cartucho herda e sobrescreve setup/on_level_up.
## Cartuchos vivem como filhos de Player.cartridge_root.
class_name CartridgeBase
extends Node

var player: Player
var level: int = 1


func setup(p_player: Player, p_level: int) -> void:
	player = p_player
	level = p_level


func on_level_up(new_level: int) -> void:
	level = new_level


## Chamado antes do nó ser removido por consumo de evolução.
## Subclasses devem reverter mudanças em stats do player (damage_mult, revives, etc).
func on_unequip() -> void:
	pass
