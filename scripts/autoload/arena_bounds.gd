## Bordas do mundo do jogo (em coordenadas de viewport 320x180).
## Singleton para entidades clampearem posição sem acoplamento com a cena.
extends Node

const DEFAULT_RECT := Rect2(Vector2.ZERO, Vector2(640, 360))

var _rect: Rect2 = DEFAULT_RECT


func set_rect(rect: Rect2) -> void:
	_rect = rect


func get_rect() -> Rect2:
	return _rect


## Retorna ponto aleatório fora do rect (usado para spawn de inimigos).
func random_spawn_point(margin: float = 8.0) -> Vector2:
	var side := randi() % 4
	var r := _rect
	match side:
		0:
			return Vector2(randf_range(r.position.x, r.end.x), r.position.y - margin)
		1:
			return Vector2(r.end.x + margin, randf_range(r.position.y, r.end.y))
		2:
			return Vector2(randf_range(r.position.x, r.end.x), r.end.y + margin)
		_:
			return Vector2(r.position.x - margin, randf_range(r.position.y, r.end.y))
