## Dual Wield — passivo que faz o player segurar 2 armas (uma em cada mão).
## Visual: segunda arma mira no inimigo mais próximo do lado oposto.
## Mecânica: +20% dano por nível (boost moderado já que o ganho principal é visual).
## Nível também aumenta o spread de "cobertura" — não vou implementar segunda arma
## atirando independente (seria invasivo em todos cartuchos), mas o boost de dano
## representa o ganho de duas armas.
extends CartridgeBase

const BASE_DAMAGE_BONUS := 0.20  ## +20% dano por nível

var _applied_mult: float = 1.0  ## último fator multiplicativo aplicado (pra reverter)


func setup(p_player: Player, p_level: int) -> void:
	super(p_player, p_level)
	p_player.set_dual_wield(true)
	_apply_bonus()


func on_level_up(new_level: int) -> void:
	super(new_level)
	_apply_bonus()


func on_unequip() -> void:
	if player != null and is_instance_valid(player):
		player.set_dual_wield(false)
		_revert_bonus()


## Aplica o bonus de dano. Reverte o anterior antes (caso seja level_up).
func _apply_bonus() -> void:
	_revert_bonus()
	if player == null:
		return
	_applied_mult = 1.0 + BASE_DAMAGE_BONUS * level
	player.damage_mult *= _applied_mult


func _revert_bonus() -> void:
	if player == null or _applied_mult <= 0.0:
		return
	if _applied_mult != 1.0:
		player.damage_mult /= _applied_mult
	_applied_mult = 1.0
