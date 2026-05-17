## Spawner de inimigos com escala de dificuldade temporal.
## Lê pool de inimigos da Era selecionada (EraRegistry).
class_name EnemySpawner
extends Node

const BASE_SPAWN_INTERVAL := 1.4
const MIN_SPAWN_INTERVAL := 0.32
# Curva de dificuldade comprimida pra cada fase de 3 min (180s).
const DIFFICULTY_RAMP_TIME := 180.0

class SpawnEntry:
	var type_id: String
	var unlock_time: float
	var weight: float

	func _init(p_id: String, p_unlock: float, p_weight: float) -> void:
		type_id = p_id
		unlock_time = p_unlock
		weight = p_weight


@export var arena_container_path: NodePath
@export var max_concurrent_enemies: int = 90

var enabled: bool = true
var _time_alive: float = 0.0
var _spawn_timer: float = 0.0
var _arena_container: Node
var _entries: Array[SpawnEntry] = []


func _ready() -> void:
	_arena_container = get_node_or_null(arena_container_path)
	if _arena_container == null:
		_arena_container = get_parent()
	_setup_entries()


## Re-popula a pool de inimigos com base na era atual do GameState e
## reseta o timer de spawn. Chamado pelo Arena ao avançar de fase.
## Em fases avançadas (stage_index > 0) começa com a curva de dificuldade
## avançada — player já está poderoso, era nova precisa ser intensa de cara.
func reset_for_new_stage() -> void:
	_spawn_timer = 0.0
	enabled = true
	_setup_entries()
	# Fase 2 em diante começa "pré-aquecida" — pula 30% da curva pra spawnar
	# mais inimigos e os de unlock_time mais tarde aparecerem cedo.
	if GameState.stage_index > 0:
		_time_alive = DIFFICULTY_RAMP_TIME * 0.3
	else:
		_time_alive = 0.0


func _setup_entries() -> void:
	_entries.clear()
	var era: EraRegistry.EraDef = EraRegistry.get_def(GameState.selected_era_id)
	if era == null:
		era = EraRegistry.get_def("era_16bit")
	for tuple in era.enemy_entries:
		# tuple = [id, unlock_time, weight]
		_entries.append(SpawnEntry.new(tuple[0], float(tuple[1]), float(tuple[2])))


func _process(delta: float) -> void:
	if not GameState.run_active or not enabled:
		return
	_time_alive += delta
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_wave()
		_spawn_timer = _current_interval()


func _current_interval() -> float:
	var t: float = clampf(_time_alive / DIFFICULTY_RAMP_TIME, 0.0, 1.0)
	return lerpf(BASE_SPAWN_INTERVAL, MIN_SPAWN_INTERVAL, t)


func _spawn_wave() -> void:
	var enemies_count := get_tree().get_nodes_in_group("enemies").size()
	if enemies_count >= max_concurrent_enemies:
		return

	var group_size := _wave_size()
	var picked_id := _pick_type()
	if picked_id == "ascii_swarm":
		group_size = max(group_size, 3 + randi() % 3)

	var origin := ArenaBounds.random_spawn_point(24.0)
	for i in group_size:
		var enemy: Enemy = _instantiate(picked_id)
		if enemy == null:
			continue
		var offset := Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
		enemy.global_position = origin + offset
		_arena_container.add_child(enemy)


func _wave_size() -> int:
	var t: float = clampf(_time_alive / DIFFICULTY_RAMP_TIME, 0.0, 1.0)
	return int(roundf(lerpf(1.0, 3.0, t)))


func _pick_type() -> String:
	var available: Array[SpawnEntry] = []
	var total_weight := 0.0
	for entry in _entries:
		if _time_alive >= entry.unlock_time:
			available.append(entry)
			total_weight += entry.weight
	if available.is_empty():
		return _entries[0].type_id if not _entries.is_empty() else "artifact"
	var roll := randf() * total_weight
	var accumulated := 0.0
	for entry in available:
		accumulated += entry.weight
		if roll <= accumulated:
			return entry.type_id
	return available.back().type_id


func _instantiate(type_id: String) -> Enemy:
	match type_id:
		"artifact":
			return Artifact.new()
		"tear":
			return Tear.new()
		"ascii_swarm":
			return AsciiSwarm.new()
		"bleed":
			return Bleed.new()
		"null_sprite":
			return NullSprite.new()
		"checksum":
			return Checksum.new()
		"echo":
			return Echo.new()
		"memory_leak":
			return MemoryLeak.new()
		"hue_shift":
			return HueShift.new()
		"compression":
			return Compression.new()
		"sprite_limit":
			return SpriteLimit.new()
		"bit_flip":
			return BitFlip.new()
		# Era 32-bit CD
		"polygon":
			return Polygon.new()
		"scratch":
			return Scratch.new()
		"fmv":
			return Fmv.new()
		# Era 64-bit
		"wireframe_hulk":
			return WireframeHulk.new()
		"z_fight":
			return ZFight.new()
	push_warning("Tipo de inimigo desconhecido: %s" % type_id)
	return Artifact.new()
