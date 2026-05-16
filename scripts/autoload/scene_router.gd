## Gerencia transições entre cenas do jogo.
## Todas as trocas passam pelo SceneTransition (fade-out → swap → fade-in).
extends Node

const MAIN_MENU := "res://scenes/main_menu.tscn"
const HUB := "res://scenes/hub.tscn"
const ARENA := "res://scenes/arena.tscn"
const GAME_OVER := "res://scenes/game_over.tscn"
const OPTIONS := "res://scenes/options.tscn"
const SPLASH := "res://scenes/splash.tscn"
const INTRO := "res://scenes/intro.tscn"


func go_to_main_menu() -> void:
	SceneTransition.go_to(MAIN_MENU)


func go_to_intro() -> void:
	SceneTransition.go_to(INTRO)


func go_to_splash() -> void:
	SceneTransition.go_to(SPLASH)


func go_to_hub() -> void:
	SceneTransition.go_to(HUB)


func go_to_arena() -> void:
	SceneTransition.go_to(ARENA)


func go_to_game_over() -> void:
	SceneTransition.go_to(GAME_OVER)


func go_to_options() -> void:
	SceneTransition.go_to(OPTIONS)


func quit() -> void:
	get_tree().quit()
