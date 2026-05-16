## SFX procedural (sfxr-style) via AudioStreamGenerator.
## Sem assets de áudio — tudo gerado em código pra estética retrô.
extends Node

enum Sfx {
	SHOOT, HIT, ENEMY_DIE, PLAYER_HURT, LEVEL_UP, PICKUP, DASH,
	UI_HOVER, UI_SELECT, UI_CONFIRM, UI_CANCEL, UI_ERROR,
}

var _players: Dictionary = {}  ## Sfx -> AudioStreamPlayer pool


func _ready() -> void:
	for sfx in Sfx.values():
		var player := AudioStreamPlayer.new()
		player.stream = _make_stream(sfx)
		player.volume_db = -8.0
		add_child(player)
		_players[sfx] = player
	# Auto-hook em todos os Buttons que entram na cena: hover/focus → UI_HOVER,
	# pressed → UI_CONFIRM. Cada Button conecta uma vez via node_added do tree.
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Button:
		var btn := node as Button
		# Evita conectar várias vezes se o mesmo Button reaparecer.
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
	var player: AudioStreamPlayer = _players.get(sfx, null)
	if player == null:
		return
	player.play()


## Cria um AudioStreamWAV pré-renderizado pra cada SFX.
func _make_stream(sfx: Sfx) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := _sfx_duration(sfx)
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit mono

	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var sample := _sfx_sample(sfx, t, duration)
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


func _sfx_duration(sfx: Sfx) -> float:
	match sfx:
		Sfx.SHOOT:
			return 0.08
		Sfx.HIT:
			return 0.05
		Sfx.ENEMY_DIE:
			return 0.18
		Sfx.PLAYER_HURT:
			return 0.25
		Sfx.LEVEL_UP:
			return 0.5
		Sfx.PICKUP:
			return 0.1
		Sfx.DASH:
			return 0.15
		Sfx.UI_HOVER:
			return 0.04
		Sfx.UI_SELECT:
			return 0.06
		Sfx.UI_CONFIRM:
			return 0.18
		Sfx.UI_CANCEL:
			return 0.16
		Sfx.UI_ERROR:
			return 0.20
	return 0.1


func _sfx_sample(sfx: Sfx, t: float, duration: float) -> float:
	var progress := t / duration
	var envelope := 1.0 - progress  # decay simples
	match sfx:
		Sfx.SHOOT:
			var freq := 880.0 * (1.0 - progress * 0.5)
			return _square(t * freq) * envelope * 0.4
		Sfx.HIT:
			return _noise(t) * envelope * 0.5
		Sfx.ENEMY_DIE:
			var freq2 := 220.0 * (1.0 - progress * 0.8)
			return (_square(t * freq2) * 0.6 + _noise(t) * 0.4) * envelope * 0.5
		Sfx.PLAYER_HURT:
			var freq3 := 110.0 + sin(t * 30.0) * 40.0
			return _square(t * freq3) * envelope * 0.6
		Sfx.LEVEL_UP:
			# Arpeggio C-E-G
			var step := int(progress * 3.0)
			var freqs := [523.25, 659.25, 783.99]
			var freq4: float = freqs[mini(step, 2)]
			return _square(t * freq4) * envelope * 0.4
		Sfx.PICKUP:
			var freq5 := 1320.0 + progress * 660.0
			return _square(t * freq5) * envelope * 0.3
		Sfx.DASH:
			return _noise(t) * (1.0 - progress) * 0.4
		Sfx.UI_HOVER:
			# Bip curto e alto, volume baixo — só "tique"
			return _square(t * 1760.0) * envelope * 0.18
		Sfx.UI_SELECT:
			# Bip um pouco mais baixo, mais firme
			return _square(t * 1320.0) * envelope * 0.28
		Sfx.UI_CONFIRM:
			# Sequência ascendente C5 → E5 → G5 (arpeggio rápido)
			var conf_step := int(progress * 3.0)
			var conf_freqs := [523.25, 659.25, 783.99]
			var conf_freq: float = conf_freqs[mini(conf_step, 2)]
			return _square(t * conf_freq) * envelope * 0.32
		Sfx.UI_CANCEL:
			# Sequência descendente E5 → C5 (mais grave que confirm)
			var cancel_step := int(progress * 2.0)
			var cancel_freqs := [659.25, 392.0]
			var cancel_freq: float = cancel_freqs[mini(cancel_step, 1)]
			return _square(t * cancel_freq) * envelope * 0.30
		Sfx.UI_ERROR:
			# Buzz dissonante grave — feedback de "não pode"
			var error_freq := 174.61 + sin(t * 24.0) * 12.0  # F3 com wobble
			return _square(t * error_freq) * envelope * 0.40
	return 0.0


func _square(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0


func _noise(t: float) -> float:
	# pseudo-random hash baseado em t
	var x := sin(t * 12345.6789) * 43758.5453
	return (x - floor(x)) * 2.0 - 1.0
