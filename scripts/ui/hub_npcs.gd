## Strip de NPCs visitantes da Coleção Eterna na hub.
## 3 personagens recorrentes (Bibliotecária, Engenheiro, Detetive Glitch) que
## o jogador pode clicar pra ouvir uma fala — cada clique escolhe uma fala
## diferente do banco, criando flavor sem repetir.
class_name HubNpcs
extends Control

const NPC_W := 124
const NPC_H := 22

# Banco de falas por NPC. Cada clique sorteia uma diferente.
const LINES_BIBLIOTECARIA := [
	"Cada cartucho tem uma alma. Catalogo todas.",
	"Não perdemos um único registro hoje. Bom serviço, GAMO.",
	"Os scripts antigos sussurram quando você não está vigiando.",
	"Limpei a poeira da gôndola lendária ontem. Brilha de novo.",
	"Lembre-se: vitória sem catalogação é só barulho.",
]
const LINES_ENGENHEIRO := [
	"Calibrei seus cartuchos. Deve estar 3% mais eficiente.",
	"Hot-swap entre eras só funciona se a placa não derreter.",
	"A engine roda em loop. Bug é só feature mal documentada.",
	"Mantive a estante a 22 graus. Estável.",
	"Se o boomerang voltar errado, é o vento. Confia.",
]
const LINES_DETETIVE := [
	"Algo aqui não bate. Tem um glitch escondido em algum lugar.",
	"Conta pra mim — você já viu o Hulk-Wireframe ANTES da Era 64?",
	"Códigos antigos. Konami sabia algo que a gente esqueceu.",
	"Cima, cima, baixo, baixo... esse padrão aparece no meu sonho.",
	"Eu investigo memória corrompida. Hoje foi um bom dia.",
]

var _played_ids: Dictionary = {}  ## npc_id -> índice da última fala (pra não repetir seguidas)
var _last_dialog_parent: Node = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()


func _build() -> void:
	var hbox := HBoxContainer.new()
	hbox.position = Vector2.ZERO
	hbox.size = size
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)

	hbox.add_child(_make_npc_btn(
		"BIBLIOTECARIA", "Bibliotecária", Color("#9bbc0f"), LINES_BIBLIOTECARIA
	))
	hbox.add_child(_make_npc_btn(
		"ENGENHEIRO", "Engenheiro", Color("#00e5ff"), LINES_ENGENHEIRO
	))
	hbox.add_child(_make_npc_btn(
		"DETETIVE_GLITCH", "Detetive Glitch", Color("#ffeb3b"), LINES_DETETIVE
	))


func _make_npc_btn(id: String, label_text: String, accent: Color, lines: Array) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(NPC_W, NPC_H)
	btn.text = "● " + label_text.to_upper()
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 2)
	btn.tooltip_text = "Clique pra conversar com %s" % label_text

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.65)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_focus := sb.duplicate() as StyleBoxFlat
	sb_focus.bg_color = Color(accent.r * 0.2, accent.g * 0.2, accent.b * 0.2, 0.95)
	sb_focus.border_color = accent
	sb_focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("hover", sb_focus)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("pressed", sb_focus)

	btn.pressed.connect(_on_npc_pressed.bind(id, label_text, accent, lines))
	return btn


func _on_npc_pressed(id: String, speaker: String, accent: Color, lines: Array) -> void:
	if lines.is_empty():
		return
	var last_idx: int = _played_ids.get(id, -1)
	var idx: int = randi() % lines.size()
	# Garante que não repete a mesma fala duas vezes seguidas (se há >=2 falas).
	if lines.size() > 1 and idx == last_idx:
		idx = (idx + 1) % lines.size()
	_played_ids[id] = idx
	_say(speaker.to_upper(), lines[idx], accent)
	Audio.play(Audio.Sfx.UI_SELECT)


func _say(speaker: String, message: String, accent: Color) -> void:
	# Limpa diálogo anterior pra evitar empilhamento.
	if _last_dialog_parent != null and is_instance_valid(_last_dialog_parent):
		for child in _last_dialog_parent.get_children():
			if child is DialogBox:
				child.queue_free()
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	var dlg := DialogBox.new()
	parent.add_child(dlg)
	dlg.show_message(speaker, message, accent)
	_last_dialog_parent = parent
