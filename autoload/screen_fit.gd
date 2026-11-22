extends Node
## Keeps UI at a comfortable size in both orientations by swapping the base
## resolution: 1280x720 for landscape, 720x1280 for portrait (phones/tablets).

const LANDSCAPE := Vector2i(1280, 720)
const PORTRAIT := Vector2i(720, 1280)


func _ready() -> void:
	get_tree().root.size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var window := get_tree().root
	var portrait := window.size.y > window.size.x
	window.content_scale_size = PORTRAIT if portrait else LANDSCAPE
