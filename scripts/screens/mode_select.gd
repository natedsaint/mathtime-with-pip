extends Control

const CARDS := [
	{"button": "PracticeButton", "mode": GameSettings.Mode.PRACTICE, "title": "Practice",
		"blurb": "No clock. Stop whenever you like.", "color": Color(0.34, 0.52, 0.96)},
	{"button": "StopwatchButton", "mode": GameSettings.Mode.STOPWATCH, "title": "Beat Your Time",
		"blurb": "How fast can you finish?", "color": Color(0.3, 0.68, 0.45)},
	{"button": "CountdownButton", "mode": GameSettings.Mode.COUNTDOWN, "title": "Countdown",
		"blurb": "How many before time runs out?", "color": Color(0.96, 0.58, 0.2)},
]


func _ready() -> void:
	for card in CARDS:
		var b: Button = get_node("%" + card["button"])
		_style_card(b, card["title"], card["blurb"], card["color"])
		b.pressed.connect(_choose.bind(card["mode"]))
	%BackButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn"))
	resized.connect(_update_layout)
	_update_layout()
	%PracticeButton.grab_focus()


func _choose(mode: GameSettings.Mode) -> void:
	GameSettings.mode = mode
	get_tree().change_scene_to_file("res://scenes/setup.tscn")


func _update_layout() -> void:
	var portrait := size.y > size.x
	%Modes.vertical = portrait
	# In portrait the title needs the room more than it needs perfect centering.
	$Margin/VBox/Header/HeaderSpacer.visible = not portrait


## Colored card with a big title and a smaller description.
func _style_card(b: Button, title: String, blurb: String, color: Color) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var box := (b.get_theme_stylebox(state) as StyleBoxFlat).duplicate() as StyleBoxFlat
		match state:
			"normal":
				box.bg_color = color
			"hover":
				box.bg_color = color.lightened(0.12)
			_:
				box.bg_color = color.darkened(0.15)
		box.border_color = box.bg_color
		b.add_theme_stylebox_override(state, box)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 20)
	b.add_child(vbox)
	for line in [[title, 52], [blurb, 32]]:
		var label := Label.new()
		label.text = line[0]
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", Color.WHITE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(label)
