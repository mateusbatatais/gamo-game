## Música chiptune procedural com 4 tracks distintas:
##   - menu (suave, ambiental)
##   - era1_normal (heroic + ritmo médio — Era 16-bit)
##   - era2_normal (etéreo + key maior, CD-era)
##   - boss (agressivo, compartilhado entre as eras)
## Toda gerada em código, sem assets externos.
extends Node

const SAMPLE_RATE := 22050
const TRACK_DURATION := 12.8  # segundos (32 beats a ~150 BPM)
const BEATS := 32
const BEAT_DURATION := TRACK_DURATION / float(BEATS)

# Pentatônica menor em C — base para Era 1 (heroica/sombria).
const PENTA_MINOR := [261.63, 311.13, 349.23, 392.00, 466.16]
# Pentatônica maior em C — base para Era 2 (etérea/disco CD).
const PENTA_MAJOR := [261.63, 293.66, 329.63, 392.00, 440.00]
# Pentatônica menor em A (mais "épica/heroica") — base do novo menu.
# A=220, C=261.63, D=293.66, E=329.63, G=392.00 — fundamental "lá menor".
const SCALE_MENU := [220.00, 261.63, 293.66, 329.63, 392.00]

# Patterns — Era 1 (heroica, ritmo direto)
const MELODY_ERA1 := [
	0, -1, 2, -1, 3, -1, 2, -1,
	4, -1, 3, -1, 2, -1, 0, -1,
	0, 2, 3, 4, 3, 2, 0, -1,
	4, 3, 2, 3, 2, 0, -1, -1,
]
const BASS_ERA1 := [0, 0, 3, 3, 4, 4, 2, 2, 0, 0, 3, 3, 4, 4, 2, 0]

# Patterns — Era 2 (CD, intervalos abertos + arpejos)
const MELODY_ERA2 := [
	2, -1, 4, -1, 2, 0, 2, -1,
	3, -1, 4, -1, 3, 2, 0, -1,
	0, 4, 3, 2, 4, 3, 0, -1,
	2, 3, 4, 3, 2, 4, 0, 2,
]
const BASS_ERA2 := [0, 0, 2, 2, 3, 3, 0, 0, 2, 2, 4, 4, 0, 0, 3, 0]

# Patterns — Boss (agressivo)
const MELODY_BOSS := [
	4, 3, 4, 3, 4, 2, 4, 2,
	3, 2, 3, 2, 3, 0, 3, 0,
	4, 4, 3, 3, 2, 2, 0, 0,
	4, 3, 2, 0, 4, 3, 2, 0,
]
const BASS_BOSS := [0, 0, 0, 0, 2, 2, 2, 2, 4, 4, 4, 4, 3, 3, 0, 0]

# Patterns — Menu (épico/aventura, pentatônica menor de Lá)
# Estrutura: A (climb) → A' (resolução) → B (climax) → A (retorno)
const MELODY_MENU := [
	# A — sobe e cai em arpejo simples (hook principal)
	0, 2, 3, 4, 3, 2, 1, 0,
	# A' — variação subindo até o topo
	0, 2, 3, 4, 4, 3, 2, 3,
	# B — climax tenso (alta + nota de resolução fora do arpejo)
	4, 3, 4, 3, 2, 3, 1, 2,
	# Volta pro hook
	0, 2, 3, 2, 3, 4, 2, 0,
]
# Baixo caminhante (uma oitava abaixo) — uma nota por 2 beats da melodia.
const BASS_MENU := [0, 0, 2, 2, 3, 3, 4, 4, 0, 0, 1, 1, 2, 2, 0, 0]

enum TrackId { MENU, ERA1, ERA2, BOSS }

var _players: Dictionary = {}  # TrackId -> AudioStreamPlayer
var _current: int = -1


func _ready() -> void:
	# Gera as 4 tracks no boot. ~3-4MB total na RAM.
	# Menu agora com pitch 1.0 (não mais reduzido), volume da melodia mais alto,
	# e usa o flag de percussão sutil pra dar groove sem ser agressivo.
	_register(TrackId.MENU,
		_generate_menu_track())
	_register(TrackId.ERA1,
		_generate_track(MELODY_ERA1, BASS_ERA1, PENTA_MINOR, 1.0, false, 0.32))
	_register(TrackId.ERA2,
		_generate_track(MELODY_ERA2, BASS_ERA2, PENTA_MAJOR, 1.08, false, 0.30))
	_register(TrackId.BOSS,
		_generate_track(MELODY_BOSS, BASS_BOSS, PENTA_MINOR, 1.18, true, 0.32))


## Track do menu — tem um "lead" extra (terça acima) na 3ª seção pra dar harmonia,
## e um click suave a cada 4 beats no canal da percussão. Volume melódico maior.
func _generate_menu_track() -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * TRACK_DURATION)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat_idx: int = int(t / BEAT_DURATION) % BEATS
		var beat_t: float = fmod(t, BEAT_DURATION) / BEAT_DURATION

		var sample: float = 0.0

		# Melodia principal (onda quadrada com envelope ADSR)
		var mel_note: int = MELODY_MENU[beat_idx]
		if mel_note >= 0 and mel_note < SCALE_MENU.size():
			var freq: float = SCALE_MENU[mel_note]
			var env: float = _envelope(beat_t)
			sample += _square(t * freq) * env * 0.34

		# Harmonia — terça acima soa só na seção B (beats 16-23) pra criar build-up
		if beat_idx >= 16 and beat_idx < 24 and mel_note >= 0:
			var harm_idx: int = (mel_note + 2) % SCALE_MENU.size()
			var h_freq: float = SCALE_MENU[harm_idx]
			var h_env: float = _envelope(beat_t)
			sample += _square(t * h_freq) * h_env * 0.20

		# Bass caminhante (uma oitava abaixo, meio-tempo)
		var bass_idx: int = (beat_idx / 2) % BASS_MENU.size()
		var bass_note: int = BASS_MENU[bass_idx]
		if bass_note >= 0 and bass_note < SCALE_MENU.size():
			var b_freq: float = SCALE_MENU[bass_note] * 0.5
			var b_env: float = _envelope(fmod(beat_t * 0.5 + (float(beat_idx % 2) * 0.5), 1.0))
			sample += _square(t * b_freq) * b_env * 0.24

		# Click ritmico sutil a cada 4 beats (não chega a ser bateria, só groove)
		if beat_idx % 4 == 0 and beat_t < 0.04:
			sample += _noise(t) * 0.08

		var value: int = clampi(int(sample * 32767.0), -32767, 32767)
		var unsigned_value: int = value if value >= 0 else value + 65536
		data[i * 2] = unsigned_value & 0xFF
		data[i * 2 + 1] = (unsigned_value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


func _register(id: int, stream: AudioStreamWAV) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -16.0
	add_child(p)
	_players[id] = p


## API pública — chamada pelas cenas pra trocar a track ativa.
func play_menu() -> void:
	_play(TrackId.MENU)


func play_normal_for_era(era_id: String) -> void:
	if era_id == "era_32bit_cd":
		_play(TrackId.ERA2)
	else:
		_play(TrackId.ERA1)


func play_normal() -> void:
	# Compat backwards — usa a era do GameState pra escolher.
	play_normal_for_era(GameState.selected_era_id)


func play_boss() -> void:
	_play(TrackId.BOSS)


func stop() -> void:
	for id in _players.keys():
		var p: AudioStreamPlayer = _players[id]
		if p.playing:
			p.stop()
	_current = -1


func _play(id: int) -> void:
	if _current == id and _players[id].playing:
		return
	# Para tudo, toca a track requisitada.
	for k in _players.keys():
		var p: AudioStreamPlayer = _players[k]
		if k != id and p.playing:
			p.stop()
	if not _players[id].playing:
		_players[id].play()
	_current = id


## Gera uma track com melodia + bass + (opcional) hi-hat clicker.
func _generate_track(
	melody: Array,
	bass: Array,
	scale: Array,
	pitch_mult: float,
	hat_clicker: bool,
	melody_volume: float
) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * TRACK_DURATION)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat_idx: int = int(t / BEAT_DURATION) % BEATS
		var beat_t: float = fmod(t, BEAT_DURATION) / BEAT_DURATION

		var sample: float = 0.0

		# Melodia
		var mel_note: int = melody[beat_idx]
		if mel_note >= 0 and mel_note < scale.size():
			var freq: float = scale[mel_note] * pitch_mult
			var env: float = _envelope(beat_t)
			sample += _square(t * freq) * env * melody_volume

		# Bass
		var bass_idx: int = (beat_idx / 2) % bass.size()
		var bass_note: int = bass[bass_idx]
		if bass_note >= 0 and bass_note < scale.size():
			var b_freq: float = scale[bass_note] * 0.5 * pitch_mult
			var b_env: float = _envelope(fmod(beat_t * 0.5 + (float(beat_idx % 2) * 0.5), 1.0))
			sample += _square(t * b_freq) * b_env * 0.22

		# Hi-hat clicker (só no boss)
		if hat_clicker and beat_idx % 4 == 0 and beat_t < 0.05:
			sample += _noise(t) * 0.2

		var value: int = clampi(int(sample * 32767.0), -32767, 32767)
		var unsigned_value: int = value if value >= 0 else value + 65536
		data[i * 2] = unsigned_value & 0xFF
		data[i * 2 + 1] = (unsigned_value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


func _envelope(beat_t: float) -> float:
	var attack := 0.02
	var release := 0.85
	if beat_t < attack:
		return beat_t / attack
	if beat_t > release:
		return clampf((1.0 - beat_t) / (1.0 - release), 0.0, 1.0)
	return 1.0 - (beat_t - attack) * 0.3


func _square(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0


func _noise(t: float) -> float:
	var x := sin(t * 12345.6789) * 43758.5453
	return (x - floor(x)) * 2.0 - 1.0
