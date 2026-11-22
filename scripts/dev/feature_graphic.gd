extends Control
## Dev screen: the Google Play feature graphic (1024x500). Render with
## godot --path . -- --shot=dev/feature_graphic --size=1024x500 --answer=0 --wait=60 --out=$PWD/store/google-play/feature-graphic.png

const BG := Color("5b86f6")
const SYMBOLS := [["+", Vector2(0.05, 0.08), -12.0], ["×", Vector2(0.88, 0.04), 10.0],
	["÷", Vector2(0.93, 0.62), -8.0], ["−", Vector2(0.40, 0.74), 6.0], ["=", Vector2(0.02, 0.66), 8.0]]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# faint oversized math symbols in the background
	for s in SYMBOLS:
		var l := Label.new()
		l.text = s[0]
		l.add_theme_font_size_override("font_size", 260)
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.13))
		l.rotation_degrees = s[2]
		add_child(l)
		l.position = Vector2(size.x * s[1].x, size.y * s[1].y)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 64)
	add_child(row)

	var pip := Pip.new()
	pip.custom_minimum_size = Vector2(Pip.W, Pip.H) * 22.0
	pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pip)
	pip.cheer(999.0) # arms up, big grin, sunny screen

	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", -10)
	row.add_child(words)
	words.add_child(_label("Mathtime", 150, Color.WHITE))
	words.add_child(_label("With Pip", 150, Color("ffd23f")))
	var tag := _label("Math flashcards that cheer you on", 46, Color(1, 1, 1, 0.92))
	tag.add_theme_constant_override("margin_top", 12)
	words.add_child(tag)


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0.1, 0.15, 0.35, 0.35))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 6)
	return l
