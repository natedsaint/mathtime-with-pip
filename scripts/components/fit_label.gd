class_name FitLabel
extends Label
## A one-line label that shrinks its font until the text fits its width
## (instead of wrapping or pushing its container wider). Used for screen titles.

@export var max_font_size := 56
@export var min_font_size := 28


func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_OFF
	clip_text = true # lets the container make us narrower than the text
	resized.connect(_fit)
	_fit.call_deferred() # after parents have set the text in their _ready


func _fit() -> void:
	var font := get_theme_font("font")
	var font_size := max_font_size
	while font_size > min_font_size \
			and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x:
		font_size -= 2
	if get_theme_font_size("font_size") != font_size:
		add_theme_font_size_override("font_size", font_size)
