## Grava histórico de posições do player para mecânicas baseadas em delay
## (ex: inimigo Echo que mimica posição passada).
extends Node

const SAMPLE_INTERVAL := 0.1
const MAX_HISTORY_SECONDS := 5.0

var _samples: Array[Vector2] = []
var _sample_timer: float = 0.0


func _ready() -> void:
	EventBus.run_started.connect(_reset)


func _reset() -> void:
	_samples.clear()
	_sample_timer = 0.0


func _process(delta: float) -> void:
	if not GameState.run_active:
		return
	_sample_timer -= delta
	if _sample_timer > 0.0:
		return
	_sample_timer = SAMPLE_INTERVAL
	var player := _find_player()
	if player == null:
		return
	_samples.append(player.global_position)
	var max_samples := int(MAX_HISTORY_SECONDS / SAMPLE_INTERVAL)
	while _samples.size() > max_samples:
		_samples.pop_front()


func get_position_seconds_ago(seconds: float) -> Vector2:
	var index_from_end := int(seconds / SAMPLE_INTERVAL)
	var idx := _samples.size() - 1 - index_from_end
	if idx < 0 or idx >= _samples.size():
		if _samples.is_empty():
			return Vector2.ZERO
		return _samples[0]
	return _samples[idx]


func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node2D
