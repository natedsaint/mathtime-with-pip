class_name NumberPad
extends GridContainer
## Big on-screen keypad. Phone layout (1 2 3 on top) with Del and OK at the bottom.

signal digit_pressed(digit: int)
signal backspace_pressed
signal submit_pressed

const KEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "Del", "0", "OK"]
const KEY_SIZE := Vector2(124, 92)

var _submit_button: Button
var _font_scale := 1.0


func _ready() -> void:
	columns = 3
	add_theme_constant_override("h_separation", 14)
	add_theme_constant_override("v_separation", 14)
	for key in KEYS:
		var b := Button.new()
		b.text = key
		b.custom_minimum_size = KEY_SIZE
		b.focus_mode = Control.FOCUS_NONE # keyboard Enter should never "click" a key
		b.add_theme_font_size_override("font_size", 48)
		add_child(b)
		match key:
			"Del":
				b.theme_type_variation = &"PadSecondary"
				b.add_theme_font_size_override("font_size", 34)
				b.pressed.connect(func() -> void: backspace_pressed.emit())
			"OK":
				b.theme_type_variation = &"PadSubmit"
				_submit_button = b
				b.pressed.connect(func() -> void: submit_pressed.emit())
			_:
				b.theme_type_variation = &"PadKey"
				var digit := int(key)
				b.pressed.connect(func() -> void: digit_pressed.emit(digit))


## Bigger keys in portrait, where the pad sits under the card.
func set_key_size(key_size: Vector2, font_scale := 1.0) -> void:
	_font_scale = font_scale
	for b in get_children():
		var button := b as Button
		button.custom_minimum_size = key_size
		var base := 34 if button.text == "Del" else (32 if button.text.length() > 2 else 48)
		button.add_theme_font_size_override("font_size", roundi(base * font_scale))


func set_submit_text(text: String) -> void:
	_submit_button.text = text
	_submit_button.add_theme_font_size_override("font_size", roundi((48 if text.length() <= 2 else 32) * _font_scale))
