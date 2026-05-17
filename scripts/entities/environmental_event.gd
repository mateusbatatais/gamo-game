## Evento ambiental temporário que acontece dentro da arena.
## Cada kind tem visual + dano próprio. Auto-libera após DURATION.
## É um Node2D que renderiza via _draw + dá dano por hit no player.
class_name EnvironmentalEvent
extends Node2D

enum Kind { DATA_STORM, BIT_RAIN, GLITCH_WAVE }

const STORM_STRIKES := 6
const STORM_STRIKE_RADIUS := 32.0
const STORM_STRIKE_DAMAGE := 18
const STORM_DURATION := 5.0

const RAIN_DROPS := 24
const RAIN_DAMAGE := 8
const RAIN_DURATION := 6.0

const WAVE_SPEED := 240.0  # px/s
const WAVE_THICKNESS := 36.0
const WAVE_DAMAGE := 22
const WAVE_DURATION := 3.5

@export var kind: int = Kind.DATA_STORM

var _age: float = 0.0
var _ended: bool = false
var _arena_rect: Rect2

# Data Storm: lista de strikes ([Vector2 pos, float telegraph_remaining, bool active])
var _strikes: Array = []
var _strike_spawn_timer: float = 0.0

# Bit Rain: drops caindo
var _drops: Array = []  # [Vector2 pos, float speed, bool collected]

# Glitch Wave: pos atual da onda
var _wave_x: float = 0.0
var _wave_dir: int = 1


func _ready() -> void:
	z_index = 50  # acima do bg, abaixo do player/inimigos
	_arena_rect = ArenaBounds.get_rect()
	EventBus.environmental_event_started.emit(kind)
	match kind:
		Kind.DATA_STORM:
			_strike_spawn_timer = 0.3
		Kind.BIT_RAIN:
			_seed_drops()
		Kind.GLITCH_WAVE:
			_wave_dir = -1 if randf() < 0.5 else 1
			_wave_x = float(_arena_rect.position.x) if _wave_dir > 0 else float(_arena_rect.end.x)


func _seed_drops() -> void:
	for i in RAIN_DROPS:
		_drops.append({
			"pos": Vector2(
				randf_range(_arena_rect.position.x, _arena_rect.end.x),
				_arena_rect.position.y - randf_range(0, 200)
			),
			"speed": randf_range(160.0, 260.0),
			"hit": false,
		})


func _process(delta: float) -> void:
	_age += delta
	var duration: float = _duration_for_kind()
	match kind:
		Kind.DATA_STORM:
			_process_data_storm(delta)
		Kind.BIT_RAIN:
			_process_bit_rain(delta)
		Kind.GLITCH_WAVE:
			_process_glitch_wave(delta)
	queue_redraw()
	if _age >= duration and not _ended:
		_ended = true
		EventBus.environmental_event_ended.emit(kind)
		queue_free()


func _duration_for_kind() -> float:
	match kind:
		Kind.DATA_STORM:
			return STORM_DURATION
		Kind.BIT_RAIN:
			return RAIN_DURATION
		Kind.GLITCH_WAVE:
			return WAVE_DURATION
	return 3.0


func _process_data_storm(delta: float) -> void:
	# Spawn strikes em posições aleatórias com 0.7s de telegraph antes de acertar.
	_strike_spawn_timer -= delta
	if _strike_spawn_timer <= 0.0 and _strikes.size() < STORM_STRIKES + 2:
		_strike_spawn_timer = 0.6
		_strikes.append({
			"pos": Vector2(
				randf_range(_arena_rect.position.x + 24, _arena_rect.end.x - 24),
				randf_range(_arena_rect.position.y + 24, _arena_rect.end.y - 24)
			),
			"telegraph": 0.7,
			"hit_age": -1.0,
		})
	# Decrementa telegraph e detecta hit no player.
	var player := _find_player()
	for s in _strikes:
		if s["telegraph"] > 0.0:
			s["telegraph"] -= delta
			if s["telegraph"] <= 0.0:
				# Acerta agora — checa player.
				s["hit_age"] = 0.0
				if player != null and player.global_position.distance_to(s["pos"]) <= STORM_STRIKE_RADIUS:
					player.take_damage(STORM_STRIKE_DAMAGE, (player.global_position - s["pos"]))
		elif s["hit_age"] >= 0.0:
			s["hit_age"] += delta


func _process_bit_rain(delta: float) -> void:
	var player := _find_player()
	for drop in _drops:
		if drop["hit"]:
			continue
		drop["pos"].y += drop["speed"] * delta
		if drop["pos"].y > _arena_rect.end.y + 8:
			# Reposiciona no topo
			drop["pos"].x = randf_range(_arena_rect.position.x, _arena_rect.end.x)
			drop["pos"].y = _arena_rect.position.y - randf_range(0, 40)
		if player != null and drop["pos"].distance_to(player.global_position) <= 10.0:
			player.take_damage(RAIN_DAMAGE, Vector2(0, 1))
			drop["hit"] = true


func _process_glitch_wave(delta: float) -> void:
	_wave_x += float(_wave_dir) * WAVE_SPEED * delta
	var player := _find_player()
	if player != null and absf(player.global_position.x - _wave_x) <= WAVE_THICKNESS * 0.5:
		player.take_damage(WAVE_DAMAGE, Vector2(float(_wave_dir), 0))


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player


# === Rendering ===

func _draw() -> void:
	match kind:
		Kind.DATA_STORM:
			_draw_data_storm()
		Kind.BIT_RAIN:
			_draw_bit_rain()
		Kind.GLITCH_WAVE:
			_draw_glitch_wave()


func _draw_data_storm() -> void:
	for s in _strikes:
		var pos: Vector2 = s["pos"]
		if s["telegraph"] > 0.0:
			# Círculo de telegraph piscando vermelho.
			var pulse: float = (sin(float(Time.get_ticks_msec()) * 0.025) + 1.0) * 0.5
			var alpha: float = lerpf(0.3, 0.7, pulse)
			draw_arc(pos, STORM_STRIKE_RADIUS, 0.0, TAU, 32,
				Color(1.0, 0.2, 0.2, alpha), 2.0)
			draw_circle(pos, STORM_STRIKE_RADIUS, Color(1.0, 0.1, 0.1, 0.10))
		elif s["hit_age"] >= 0.0 and s["hit_age"] < 0.4:
			# Flash de impacto branco encolhendo.
			var t: float = s["hit_age"] / 0.4
			var r: float = STORM_STRIKE_RADIUS * (1.0 - t * 0.5)
			var a: float = 1.0 - t
			draw_circle(pos, r, Color(1.0, 1.0, 0.5, a * 0.6))
			draw_circle(pos, r * 0.4, Color(1.0, 1.0, 1.0, a))


func _draw_bit_rain() -> void:
	for drop in _drops:
		if drop["hit"]:
			continue
		var p: Vector2 = drop["pos"]
		# Drop = retângulo pequeno verde-fluor com rastro.
		draw_rect(Rect2(p - Vector2(1.5, 4.0), Vector2(3, 8)),
			Color(0.6, 1.0, 0.4, 0.85), true)
		draw_rect(Rect2(p - Vector2(1.0, 10.0), Vector2(2, 6)),
			Color(0.6, 1.0, 0.4, 0.40), true)


func _draw_glitch_wave() -> void:
	# Onda vertical magenta com noise sutil.
	var x: float = _wave_x
	var thickness: float = WAVE_THICKNESS
	for layer in 4:
		var t: float = float(layer) / 4.0
		var w: float = thickness * (1.0 - t * 0.5)
		var alpha: float = (1.0 - t) * 0.5
		var col := Color(0.95, 0.2, 0.8, alpha)
		draw_rect(Rect2(x - w * 0.5, _arena_rect.position.y, w, _arena_rect.size.y),
			col, true)
	# Borda interna mais saturada
	draw_rect(Rect2(x - 2.0, _arena_rect.position.y, 4.0, _arena_rect.size.y),
		Color(1.0, 1.0, 1.0, 0.6), true)
