extends Control
## Dev screen: every Pip mood side by side. Screenshot with
## godot --path . -- --shot=dev/pip_gallery --out=/tmp/pip.png

const MOODS := ["idle", "cheer", "think", "show 56", "tap", "5 taps"]


func _ready() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	add_child(row)
	for mood in MOODS:
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(col)
		var pip := Pip.new()
		pip.custom_minimum_size = Vector2(Pip.W, Pip.H) * 8.0
		col.add_child(pip)
		var label := Label.new()
		label.text = mood
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		col.add_child(label)
		match mood:
			"cheer":
				pip.cheer(999)
			"celebrate":
				pip.celebrate(999)
			"think":
				pip.think(999)
			"show 56":
				pip.show_number(56)
			"show 144":
				pip.show_number(144)
			"wave":
				pip.wave(999)
			"tap":
				pip.poke()
			"5 taps":
				for i in Pip.DIZZY_TAPS:
					pip.poke()
