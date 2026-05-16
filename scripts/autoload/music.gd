## Música chiptune procedural — gera um loop curto com melodia em onda quadrada
## + linha de baixo em meio-tempo. Dois tracks: "normal" e "boss" (mais agressivo).
## Toda a geração é em código, sem assets externos.
extends Node

const SAMPLE_RATE := 22050
const TRACK_DURATION := 12.8  # segundos (32 beats a ~150 BPM)
const BEATS := 32
const BEAT_DURATION := TRACK_DURATION / float(BEATS)

# Pentatônica menor em C (sempre soa "ok"): C, Eb, F, G, Bb
const PENTA := [261.63, 311.13, 349.23, 392.00, 466.16]

# Pattern da melodia (32 beats — índice na pentatônica, -1 = silêncio)
const MELODY_NORMAL := [
	0, -1, 2, -1, 3, -1, 2, -1,
	4, -1, 3, -1, 2, -1, 0, -1,
	0, 2, 3, 4, 3, 2, 0, -1,
	4, 3, 2, 3, 2, 0, -1, -1,
]

const MELODY_BOSS := [
	4, 3, 4, 3, 4, 2, 4, 2,
	3, 2, 3, 2, 3, 0, 3, 0,
	4, 4, 3, 3, 2, 2, 0, 0,
	4, 3, 2, 0, 4, 3, 2, 0,
]

# Linha de baixo a metade do tempo (16 entradas) — uma oitava abaixo.
const BASS_NORMAL := [0, 0, 3, 3, 4, 4, 2, 2, 0, 0, 3, 3, 4, 4, 2, 0]
const BASS_BOSS   := [0, 0, 0, 0, 2, 2, 2, 2, 4, 4, 4, 4, 3, 3, 0, 0]

var _normal_player: AudioStreamPlayer
var _boss_player: AudioStreamPlayer
var _is_boss_mode: bool = false


func _ready() -> void:
	var normal := _generate_track(MELODY_NORMAL, BASS_NORMAL, 1.0)
	var boss := _generate_track(MELODY_BOSS, BASS_BOSS, 1.18)
	_normal_player = _make_player(normal, -16.0)
	_boss_player = _make_player(boss, -16.0)
	add_child(_normal_player)
	add_child(_boss_player)


func _make_player(stream: AudioStreamWAV, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	return p


## Toca a música normal (chamado no início da run).
func play_normal() -> void:
	_is_boss_mode = false
	if _boss_player.playing:
		_boss_player.stop()
	if not _normal_player.playing:
		_normal_player.play()


## Troca para a track agressiva (chamado no boss warning).
func play_boss() -> void:
	if _is_boss_mode:
		return
	_is_boss_mode = true
	if _normal_player.playing:
		_normal_player.stop()
	_boss_player.play()


## Para toda a música (game over).
func stop() -> void:
	_normal_player.stop()
	_boss_player.stop()
	_is_boss_mode = false


func _generate_track(melody: Array, bass: Array, pitch_mult: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * TRACK_DURATION)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat_idx: int = int(t / BEAT_DURATION) % BEATS
		var beat_t: float = fmod(t, BEAT_DURATION) / BEAT_DURATION  # 0..1 dentro do beat

		var sample: float = 0.0

		# Melodia (onda quadrada com envelope ADSR curto)
		var mel_note: int = melody[beat_idx]
		if mel_note >= 0:
			var freq: float = PENTA[mel_note] * pitch_mult
			var env: float = _envelope(beat_t)
			sample += _square(t * freq) * env * 0.32

		# Bass (uma oitava abaixo, meio-tempo, sustained mais longo)
		var bass_idx: int = (beat_idx / 2) % bass.size()
		var bass_note: int = bass[bass_idx]
		if bass_note >= 0:
			var b_freq: float = PENTA[bass_note] * 0.5 * pitch_mult
			var b_env: float = _envelope(fmod(beat_t * 0.5 + (float(beat_idx % 2) * 0.5), 1.0))
			sample += _square(t * b_freq) * b_env * 0.22

		# Hat clicker a cada 4 beats (só no boss track)
		if pitch_mult > 1.0 and beat_idx % 4 == 0 and beat_t < 0.05:
			sample += _noise(t) * 0.2

		# Clamp
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
	# Attack rápido + decay/sustain pra dar punch tipo NES.
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
