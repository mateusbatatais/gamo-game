## SFX procedural com VARIANTES POR ERA — gameplay sounds evoluem conforme
## o jogador avança 16-bit → 32-bit CD → 64-bit. UI sfx ficam globais (sem
## variação) já que rodam em menus fora da run.
##
## Era 1 (16-bit SNES style): square waves chunky, simples, punchy
## Era 2 (32-bit CD style):   2 osciladores detuned, decay maior, "wet"
## Era 3 (64-bit N64 style):  sub-bass, distortion, layered, mais pesado
extends Node

enum Sfx {
	SHOOT, HIT, ENEMY_DIE, PLAYER_HURT, LEVEL_UP, PICKUP, DASH,
	UI_HOVER, UI_SELECT, UI_CONFIRM, UI_CANCEL, UI_ERROR,
}

enum Era { E1, E2, E3 }

## Pool de players. Key composta = sfx * 10 + era (era=0 para UI sfx genéricos).
## Cada key tem um Array de players (pool) pra permitir overlap em rapid fire.
var _players: Dictionary = {}  ## int -> Array[AudioStreamPlayer]
## Índice round-robin por key (qual player do pool usar na próxima play()).
var _pool_index: Dictionary = {}  ## int -> int

const POOL_SIZE := 4  ## quantos players por (sfx, era) — permite até 4 sobreposições

## Quais SFX têm variantes por era (gameplay). Resto compartilha 1 stream.
const ERA_VARYING: Array[int] = [
	Sfx.SHOOT, Sfx.HIT, Sfx.ENEMY_DIE, Sfx.PLAYER_HURT, Sfx.PICKUP, Sfx.LEVEL_UP, Sfx.DASH,
]


func _ready() -> void:
	for sfx in Sfx.values():
		if sfx in ERA_VARYING:
			# Pré-gera 3 variantes (1 por era), cada uma com pool de N players.
			for era in [Era.E1, Era.E2, Era.E3]:
				_register_pool(_key(sfx, era), _make_stream(sfx, era))
		else:
			# UI sfx — 1 variante só, pool com 2 players (UI clicks raramente sobrepõe).
			_register_pool(_key(sfx, -1), _make_stream(sfx, Era.E1), 2)
	# Auto-hook em Buttons (UI_HOVER no foco, UI_CONFIRM no pressed).
	get_tree().node_added.connect(_on_node_added)


## Cria um pool de N players com mesmo stream sob a key dada.
func _register_pool(key: int, stream: AudioStreamWAV, size: int = POOL_SIZE) -> void:
	var pool: Array[AudioStreamPlayer] = []
	for i in size:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = -8.0
		add_child(p)
		pool.append(p)
	_players[key] = pool
	_pool_index[key] = 0


func _key(sfx: int, era: int) -> int:
	return sfx * 10 + era + 1  ## +1 pra acomodar era=-1 (UI)


func _current_era() -> Era:
	match GameState.selected_era_id:
		"era_32bit_cd":
			return Era.E2
		"era_64bit":
			return Era.E3
	return Era.E1


func _on_node_added(node: Node) -> void:
	if node is Button:
		var btn := node as Button
		if not btn.has_meta("audio_hooked"):
			btn.set_meta("audio_hooked", true)
			btn.mouse_entered.connect(_on_button_hover)
			btn.focus_entered.connect(_on_button_hover)
			btn.pressed.connect(_on_button_confirm)


func _on_button_hover() -> void:
	play(Sfx.UI_HOVER)


func _on_button_confirm() -> void:
	play(Sfx.UI_CONFIRM)


func play(sfx: Sfx) -> void:
	var key: int
	if sfx in ERA_VARYING:
		key = _key(sfx, _current_era())
	else:
		key = _key(sfx, -1)
	var pool: Array = _players.get(key, [])
	if pool.is_empty():
		return
	# Estratégia: prefere player ocioso. Se todos tocando, usa round-robin
	# (corta o mais antigo) pra não engasgar em rapid fire.
	var chosen: AudioStreamPlayer = null
	for p in pool:
		if p is AudioStreamPlayer and not (p as AudioStreamPlayer).playing:
			chosen = p
			break
	if chosen == null:
		var idx: int = int(_pool_index.get(key, 0))
		chosen = pool[idx]
		_pool_index[key] = (idx + 1) % pool.size()
	chosen.play()


## Gera o stream pré-renderizado pra (sfx, era).
func _make_stream(sfx: Sfx, era: Era) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := _sfx_duration(sfx, era)
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var sample := _sfx_sample(sfx, t, duration, era)
		var value: int = clampi(int(sample * 32767.0), -32767, 32767)
		var unsigned_value: int = value if value >= 0 else value + 65536
		data[i * 2] = unsigned_value & 0xFF
		data[i * 2 + 1] = (unsigned_value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _sfx_duration(sfx: Sfx, era: Era) -> float:
	# Eras posteriores têm sons ligeiramente mais longos (mais "produzidos").
	var base: float = 0.0
	match sfx:
		Sfx.SHOOT:        base = 0.08
		Sfx.HIT:          base = 0.05
		Sfx.ENEMY_DIE:    base = 0.18
		Sfx.PLAYER_HURT:  base = 0.25
		Sfx.LEVEL_UP:     base = 0.50
		Sfx.PICKUP:       base = 0.10
		Sfx.DASH:         base = 0.15
		Sfx.UI_HOVER:     base = 0.04
		Sfx.UI_SELECT:    base = 0.06
		Sfx.UI_CONFIRM:   base = 0.18
		Sfx.UI_CANCEL:    base = 0.16
		Sfx.UI_ERROR:     base = 0.20
		_:                base = 0.10
	# Era 2 = +25%, Era 3 = +50% pra sons mais "ricos"
	if sfx in ERA_VARYING:
		match era:
			Era.E2: base *= 1.25
			Era.E3: base *= 1.5
	return base


func _sfx_sample(sfx: Sfx, t: float, duration: float, era: Era) -> float:
	var progress := t / duration
	var envelope := 1.0 - progress
	# UI sfx idênticos em todas eras.
	match sfx:
		Sfx.UI_HOVER:
			return _square(t * 1760.0) * envelope * 0.18
		Sfx.UI_SELECT:
			return _square(t * 1320.0) * envelope * 0.28
		Sfx.UI_CONFIRM:
			var conf_step := int(progress * 3.0)
			var conf_freqs := [523.25, 659.25, 783.99]
			var conf_freq: float = conf_freqs[mini(conf_step, 2)]
			return _square(t * conf_freq) * envelope * 0.32
		Sfx.UI_CANCEL:
			var cancel_step := int(progress * 2.0)
			var cancel_freqs := [659.25, 392.0]
			var cancel_freq: float = cancel_freqs[mini(cancel_step, 1)]
			return _square(t * cancel_freq) * envelope * 0.30
		Sfx.UI_ERROR:
			var error_freq := 174.61 + sin(t * 24.0) * 12.0
			return _square(t * error_freq) * envelope * 0.40
	# Gameplay sfx — branch por era.
	match sfx:
		Sfx.SHOOT:
			return _shoot(t, progress, envelope, era)
		Sfx.HIT:
			return _hit(t, progress, envelope, era)
		Sfx.ENEMY_DIE:
			return _enemy_die(t, progress, envelope, era)
		Sfx.PLAYER_HURT:
			return _player_hurt(t, progress, envelope, era)
		Sfx.LEVEL_UP:
			return _level_up(t, progress, envelope, era)
		Sfx.PICKUP:
			return _pickup(t, progress, envelope, era)
		Sfx.DASH:
			return _dash(t, progress, envelope, era)
	return 0.0


# --- SHOOT ---
# E1: square 880→440Hz chunky
# E2: 2 osciladores detuned com pitch sweep + curta cauda
# E3: sub-bass + crunch (chunky pesado)
func _shoot(t: float, progress: float, env: float, era: Era) -> float:
	match era:
		Era.E1:
			var freq := 880.0 * (1.0 - progress * 0.5)
			return _square(t * freq) * env * 0.4
		Era.E2:
			# Dois oscs detuned + sweep maior pra ficar "laser"
			var freq_a := 1100.0 * (1.0 - progress * 0.7)
			var freq_b := freq_a - 8.0  # detune pra wobble
			var s := _square(t * freq_a) * 0.30 + _square(t * freq_b) * 0.22
			return s * env * 0.7
		Era.E3:
			# Sub-bass com pitch drop + ruído de "crunch"
			var freq2 := 620.0 * (1.0 - progress * 0.6)
			var sub := sin(t * freq2 * 0.5 * TAU) * 0.35
			var mid := _square(t * freq2) * 0.30
			var crunch := _noise(t) * 0.12 * (1.0 - progress)
			return (sub + mid + crunch) * env * 0.55
	return 0.0


# --- HIT ---
# E1: noise burst
# E2: filtered noise (sweep)
# E3: heavy impact com sub
func _hit(t: float, _progress: float, env: float, era: Era) -> float:
	match era:
		Era.E1:
			return _noise(t) * env * 0.5
		Era.E2:
			# Mix de noise + tom curto
			var tone := _square(t * 440.0) * 0.25
			return (tone + _noise(t) * 0.4) * env * 0.55
		Era.E3:
			# Impact pesado: sub-thump + crunch noise
			var thump := sin(t * 80.0 * TAU) * 0.5
			var crunch := _noise(t) * 0.4
			return (thump + crunch) * env * 0.6
	return 0.0


# --- ENEMY DIE ---
# E1: square descending + noise
# E2: harmonic stack descending com cauda longa
# E3: sub-explosion + rumble
func _enemy_die(t: float, progress: float, env: float, era: Era) -> float:
	match era:
		Era.E1:
			var freq := 220.0 * (1.0 - progress * 0.8)
			return (_square(t * freq) * 0.6 + _noise(t) * 0.4) * env * 0.5
		Era.E2:
			# Acorde descendente: 3 squares paralelos
			var f1 := 330.0 * (1.0 - progress * 0.7)
			var f2 := f1 * 1.5  # 5ª
			var f3 := f1 * 0.5  # oitava abaixo
			var s := _square(t * f1) * 0.25 + _square(t * f2) * 0.18 + _square(t * f3) * 0.20
			s += _noise(t) * 0.20 * (1.0 - progress * 0.5)
			return s * env * 0.55
		Era.E3:
			# Explosão pesada: sub-bass com pitch drop + rumble noise sustentado
			var freq3 := 150.0 * (1.0 - progress * 0.85)
			var sub := sin(t * freq3 * TAU) * 0.5
			var rumble := _noise(t) * 0.45
			return (sub + rumble) * env * 0.6
	return 0.0


# --- PLAYER HURT ---
# E1: wobble low square
# E2: detuned wobble com vibrato
# E3: distorted growl
func _player_hurt(t: float, _progress: float, env: float, era: Era) -> float:
	match era:
		Era.E1:
			var freq := 110.0 + sin(t * 30.0) * 40.0
			return _square(t * freq) * env * 0.6
		Era.E2:
			# Wobble com 2 osciladores em quintas pra som mais alarmante
			var freq_a := 130.0 + sin(t * 24.0) * 50.0
			var freq_b := freq_a * 1.5
			var s := _square(t * freq_a) * 0.4 + _square(t * freq_b) * 0.25
			return s * env * 0.55
		Era.E3:
			# Growl distorcido — saturated square + sub
			var freq3 := 90.0 + sin(t * 18.0) * 35.0
			var raw := _square(t * freq3) * 0.7
			# Saturação: clip pra dar distortion
			raw = clampf(raw * 1.5, -1.0, 1.0)
			var sub := sin(t * 60.0 * TAU) * 0.3
			return (raw + sub) * env * 0.55
	return 0.0


# --- LEVEL UP ---
# E1: arpeggio C-E-G square
# E2: arpeggio com harmonia (5ª acima) e mais notas
# E3: power chord ascendente (5ths) com sub
func _level_up(t: float, progress: float, env: float, era: Era) -> float:
	match era:
		Era.E1:
			var step := int(progress * 3.0)
			var freqs := [523.25, 659.25, 783.99]
			var freq: float = freqs[mini(step, 2)]
			return _square(t * freq) * env * 0.4
		Era.E2:
			var step := int(progress * 4.0)
			var freqs := [523.25, 659.25, 783.99, 1046.50]  # C-E-G-C8va
			var freq: float = freqs[mini(step, 3)]
			var harm: float = freq * 1.5  # quinta
			var s := _square(t * freq) * 0.35 + _square(t * harm) * 0.22
			return s * env * 0.5
		Era.E3:
			var step := int(progress * 4.0)
			var freqs := [392.0, 523.25, 659.25, 783.99]  # G-C-E-G
			var freq: float = freqs[mini(step, 3)]
			var sub := sin(t * freq * 0.25 * TAU) * 0.3
			var main := _square(t * freq) * 0.4
			var fifth := _square(t * freq * 1.5) * 0.25
			return (sub + main + fifth) * env * 0.5
	return 0.0


# --- PICKUP ---
# E1: rising square chirp
# E2: bell-like (2 harmonics) com decay
# E3: rich chord ascendente
func _pickup(t: float, progress: float, env: float, era: Era) -> float:
	match era:
		Era.E1:
			var freq := 1320.0 + progress * 660.0
			return _square(t * freq) * env * 0.3
		Era.E2:
			# Bell: 2 senóides em harmonia maior
			var freq := 1320.0 + progress * 660.0
			var bell := sin(t * freq * TAU) * 0.3 + sin(t * freq * 2.0 * TAU) * 0.15
			return bell * env * 0.5
		Era.E3:
			# Chord ascendente
			var freq := 880.0 + progress * 440.0
			var s := (
				_square(t * freq) * 0.20
				+ _square(t * freq * 1.25) * 0.18  # 3ª maior
				+ _square(t * freq * 1.5) * 0.18   # 5ª
				+ sin(t * freq * 0.5 * TAU) * 0.2  # sub
			)
			return s * env * 0.45
	return 0.0


# --- DASH ---
# E1: noise rajada
# E2: noise filtrado + whoosh tonal
# E3: rumble + whoosh com sub
func _dash(t: float, progress: float, _env: float, era: Era) -> float:
	match era:
		Era.E1:
			return _noise(t) * (1.0 - progress) * 0.4
		Era.E2:
			var whoosh := _noise(t) * (1.0 - progress) * 0.4
			var tone := sin(t * 660.0 * TAU * (1.0 - progress * 0.7)) * 0.15
			return whoosh + tone
		Era.E3:
			var rumble := _noise(t) * (1.0 - progress) * 0.4
			var sub := sin(t * 120.0 * TAU) * 0.3 * (1.0 - progress)
			return rumble + sub
	return 0.0


func _square(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0


func _noise(t: float) -> float:
	var x := sin(t * 12345.6789) * 43758.5453
	return (x - floor(x)) * 2.0 - 1.0
