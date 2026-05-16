## Sistema simples de i18n via dicionário in-memory.
## Use `I18n.t("key")` em qualquer lugar pra obter a string traduzida.
extends Node

signal locale_changed(new_locale: String)

const DEFAULT_LOCALE := "pt_BR"

const STRINGS := {
	"pt_BR": {
		# Menu Principal
		"menu_title": "CARTRIDGE\nCRUSADE",
		"menu_play": "JOGAR",
		"menu_options": "OPCOES",
		"menu_quit": "SAIR",
		"menu_version": "v0.5 - Era 16-bit",
		"menu_controls_hint": "WASD/SETAS MOVE  -  ESPACO DASH",

		# Hub
		"hub_title": "A ESTANTE",
		"hub_era": "ERA",
		"hub_spirits": "SPIRITS",
		"hub_collection": "COLECAO",
		"hub_collected_count": "%d / %d coletados",
		"hub_locked": "BLOQUEADO",
		"hub_unknown": "????",
		"hub_play": "JOGAR",
		"hub_back": "MENU",
		"hub_best_time": "Best",
		"hub_kills": "Kills",
		"hub_runs": "Runs",

		# Options
		"options_title": "OPCOES",
		"options_audio": "AUDIO",
		"options_video": "VIDEO",
		"options_a11y": "ACESSIBILIDADE",
		"options_controls": "CONTROLES",
		"options_volume_master": "Volume Master",
		"options_volume_sfx": "Volume SFX",
		"options_fullscreen": "Tela Cheia",
		"options_crt": "Shader CRT (scanlines + curvatura)",
		"options_screen_shake": "Screen Shake",
		"options_photosensitive": "Modo Fotossensivel (reduz flashes)",
		"options_language": "Idioma",
		"options_back": "VOLTAR",
		"options_rebind_press": "Pressione uma tecla...",

		# Game Over
		"go_victory": "VITORIA",
		"go_defeat": "GAME OVER",
		"go_victory_sub": "CORRUPTION PURGED",
		"go_defeat_sub": "THE GLITCH PREVAILS",
		"go_time": "TEMPO",
		"go_kills": "KILLS",
		"go_retry": "REJOGAR",
		"go_menu": "MENU",
		"go_reward": "+ %s (Lendario)",

		# HUD
		"hud_hp": "HP %d/%d",
		"hud_kills": "KILLS %d",
		"hud_level": "LV %d",
		"hud_warning_boss": "WARNING - CORRUPTION INCOMING",
		"hud_purged": "PURGED",

		# Level Up
		"lvl_up_title": "LEVEL UP",
		"lvl_up_subtitle": "ESCOLHA UM CARTUCHO",
		"lvl_up_new": "NOVO",
		"lvl_up_level": "LV %d -> %d",
		"lvl_up_weapon": "ARMA",
		"lvl_up_passive": "PASSIVO",

		# Pause
		"pause_title": "PAUSADO",
		"pause_resume": "CONTINUAR",
		"pause_menu": "MENU PRINCIPAL",
		"pause_quit": "SAIR",
	},
	"en": {
		"menu_title": "CARTRIDGE\nCRUSADE",
		"menu_play": "PLAY",
		"menu_options": "OPTIONS",
		"menu_quit": "QUIT",
		"menu_version": "v0.5 - 16-bit Era",
		"menu_controls_hint": "WASD/ARROWS MOVE  -  SPACE DASH",

		"hub_title": "THE SHELF",
		"hub_era": "ERA",
		"hub_spirits": "SPIRITS",
		"hub_collection": "COLLECTION",
		"hub_collected_count": "%d / %d collected",
		"hub_locked": "LOCKED",
		"hub_unknown": "????",
		"hub_play": "PLAY",
		"hub_back": "MENU",
		"hub_best_time": "Best",
		"hub_kills": "Kills",
		"hub_runs": "Runs",

		"options_title": "OPTIONS",
		"options_audio": "AUDIO",
		"options_video": "VIDEO",
		"options_a11y": "ACCESSIBILITY",
		"options_controls": "CONTROLS",
		"options_volume_master": "Master Volume",
		"options_volume_sfx": "SFX Volume",
		"options_fullscreen": "Fullscreen",
		"options_crt": "CRT Shader (scanlines + curvature)",
		"options_screen_shake": "Screen Shake",
		"options_photosensitive": "Photosensitive Mode (reduces flashes)",
		"options_language": "Language",
		"options_back": "BACK",
		"options_rebind_press": "Press a key...",

		"go_victory": "VICTORY",
		"go_defeat": "GAME OVER",
		"go_victory_sub": "CORRUPTION PURGED",
		"go_defeat_sub": "THE GLITCH PREVAILS",
		"go_time": "TIME",
		"go_kills": "KILLS",
		"go_retry": "RETRY",
		"go_menu": "MENU",
		"go_reward": "+ %s (Legendary)",

		"hud_hp": "HP %d/%d",
		"hud_kills": "KILLS %d",
		"hud_level": "LV %d",
		"hud_warning_boss": "WARNING - CORRUPTION INCOMING",
		"hud_purged": "PURGED",

		"lvl_up_title": "LEVEL UP",
		"lvl_up_subtitle": "PICK A CARTRIDGE",
		"lvl_up_new": "NEW",
		"lvl_up_level": "LV %d -> %d",
		"lvl_up_weapon": "WEAPON",
		"lvl_up_passive": "PASSIVE",

		"pause_title": "PAUSED",
		"pause_resume": "RESUME",
		"pause_menu": "MAIN MENU",
		"pause_quit": "QUIT",
	},
}

var current_locale: String = DEFAULT_LOCALE


## Retorna a string traduzida pro locale atual. Fallback: a chave literal.
func t(key: String) -> String:
	var locale_dict: Dictionary = STRINGS.get(current_locale, STRINGS[DEFAULT_LOCALE])
	return locale_dict.get(key, key)


## Atalho que formata com args (substitui o uso de % manualmente).
func tf(key: String, args: Array) -> String:
	var template := t(key)
	if args.is_empty():
		return template
	return template % args


func set_locale(new_locale: String) -> void:
	if not STRINGS.has(new_locale):
		return
	if new_locale == current_locale:
		return
	current_locale = new_locale
	locale_changed.emit(new_locale)


func available_locales() -> Array[String]:
	var out: Array[String] = []
	for k in STRINGS.keys():
		out.append(k)
	return out


func locale_display_name(locale: String) -> String:
	match locale:
		"pt_BR":
			return "Portugues"
		"en":
			return "English"
	return locale
