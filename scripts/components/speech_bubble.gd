class_name SpeechBubble
extends PanelContainer
## Pixel-style speech bubble with a tail pointing right (toward Pip).
## Stays in the layout when empty (just invisible) so nothing jumps around.

const INK := Color("2b2d42")
const T := 6.0 # tail pixel size (matches the 6px border)

var _label := Label.new()


func _ready() -> void:
	theme_type_variation = &"Bubble"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 28)
	add_child(_label)
	modulate.a = 0.0


func say(text: String, color := INK) -> void:
	if text.is_empty():
		create_tween().tween_property(self, "modulate:a", 0.0, 0.15)
		return
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	modulate.a = 1.0
	pivot_offset = Vector2(size.x, size.y / 2.0)
	scale = Vector2.ONE * 0.85
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(self, "scale", Vector2.ONE, 0.25)


func _draw() -> void:
	# Stair-stepped pixel tail: dark outline, white inside, joined to the border.
	var mid := roundf(size.y / 2.0)
	for i in 3:
		var h := (5 - i * 2) * T
		draw_rect(Rect2(size.x + i * T, mid - h / 2.0, T, h), INK)
	draw_rect(Rect2(size.x - T, mid - 1.5 * T, 2 * T, 3 * T), Color.WHITE)
	draw_rect(Rect2(size.x + T, mid - 0.5 * T, T, T), Color.WHITE)
