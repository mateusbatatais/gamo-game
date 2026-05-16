## Label que escreve o texto caractere por caractere, com beep por char.
## Uso:
##   var tw := TypewriterLabel.new()
##   tw.position = ...
##   add_child(tw)
##   tw.type_text("CHEFE FINAL", 0.04)
class_name TypewriterLabel
extends Label

const SOUND_INTERVAL := 3  # toca som a cada N chars (evita spam)

signal finished

var _full_text: String = ""
var _char_index: int = 0
var _char_interval: float = 0.04
var _timer: float = 0.0
var _typing: bool = false
var _play_sound: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Inicia o efeito typewriter. char_interval = segundos por char.
func type_text(text: String, char_interval: float = 0.04, play_sound: bool = true) -> void:
	_full_text = text
	_char_interval = char_interval
	_play_sound = play_sound
	_char_index = 0
	_timer = 0.0
	_typing = true
	self.text = ""


## Termina imediatamente (skip).
func finish_now() -> void:
	if not _typing:
		return
	_typing = false
	self.text = _full_text
	_char_index = _full_text.length()
	finished.emit()


func _process(delta: float) -> void:
	if not _typing:
		return
	_timer -= delta
	while _timer <= 0.0 and _char_index < _full_text.length():
		_timer += _char_interval
		_char_index += 1
		self.text = _full_text.substr(0, _char_index)
		if _play_sound and _char_index % SOUND_INTERVAL == 0:
			# Reusa UI_HOVER por ser curto e neutro
			Audio.play(Audio.Sfx.UI_HOVER)
	if _char_index >= _full_text.length():
		_typing = false
		finished.emit()
