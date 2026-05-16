## Barramento global de eventos do jogo.
## Use este singleton para sinais cross-system, evitando acoplamento direto.
extends Node

# --- Run lifecycle ---
signal run_started
signal run_ended(victory: bool, stats: Dictionary)
signal run_paused(paused: bool)

# --- Player ---
signal player_damaged(amount: int, current_hp: int, max_hp: int)
signal player_healed(amount: int, current_hp: int, max_hp: int)
signal player_died

# --- XP / Level ---
signal xp_gained(amount: int, current_xp: int, xp_needed: int)
signal player_leveled_up(new_level: int)
signal level_up_choice_made(cartridge_id: String)

# --- Enemies ---
signal enemy_spawned(enemy: Node2D)
signal enemy_killed(enemy: Node2D, xp_value: int)

# --- Cartridges ---
signal cartridge_equipped(cartridge_id: String)
signal cartridge_collected(cartridge_id: String)

# --- Power-ups e combo ---
signal power_up_collected(kind: int)
signal combo_changed(combo: int)
signal mini_boss_spawned

# --- Tokens / Upgrades / Achievements ---
signal tokens_changed(total: int)
signal achievement_unlocked(id: String)

# --- Boss ---
signal boss_warning  # antes do boss aparecer
signal boss_spawned(boss: Node2D)
signal boss_damaged(current_hp: int, max_hp: int)
signal boss_defeated
