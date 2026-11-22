extends Control
## Pick operations, level, and (for timed modes) how many cards / how long.

const OP_LABELS := {
	Question.Op.ADD: "+  Add",
	Question.Op.SUB: "−  Subtract",
	Question.Op.MUL: "×  Multiply",
	Question.Op.DIV: "÷  Divide",
}

var _op_buttons := {}


func _ready() -> void:
	%TitleLabel.text = GameSettings.MODE_TITLES[GameSettings.mode]
	%BackButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))
	%StartButton.pressed.connect(_on_start)

	for op in OP_LABELS:
		var b := _chip(OP_LABELS[op], %OpsRow)
		b.button_pressed = op in GameSettings.ops
		b.toggled.connect(_on_op_toggled.bind(op))
		_op_buttons[op] = b

	var level_group := ButtonGroup.new()
	for i in GameSettings.LEVEL_NAMES.size():
		var b := _chip("%d  %s" % [i + 1, GameSettings.LEVEL_NAMES[i]], %LevelRow)
		b.button_group = level_group
		b.button_pressed = (i + 1) == GameSettings.level
		b.pressed.connect(func() -> void: GameSettings.level = i + 1)

	var length_group := ButtonGroup.new()
	match GameSettings.mode:
		GameSettings.Mode.STOPWATCH:
			%LengthLabel.text = "How many cards?"
			for n in GameSettings.COUNT_OPTIONS:
				var b := _chip("%d cards" % n, %LengthRow)
				b.button_group = length_group
				b.button_pressed = n == GameSettings.question_count
				b.pressed.connect(func() -> void: GameSettings.question_count = n)
			# The run is always timed; this only hides the ticking clock while playing.
			%ClockCol.show()
			var clock_group := ButtonGroup.new()
			for show in [true, false]:
				var b := _chip("Show it" if show else "Hide it", %ClockRow)
				b.button_group = clock_group
				b.button_pressed = show == GameSettings.show_clock
				b.pressed.connect(func() -> void: GameSettings.show_clock = show)
		GameSettings.Mode.COUNTDOWN:
			%LengthLabel.text = "How long?"
			for s in GameSettings.DURATION_OPTIONS:
				var b := _chip(GameSettings.duration_label(s), %LengthRow)
				b.button_group = length_group
				b.button_pressed = s == GameSettings.duration_sec
				b.pressed.connect(func() -> void: GameSettings.duration_sec = s)
		_:
			%LengthAndClock.hide()
	resized.connect(_update_layout)
	_update_layout()

	%StartButton.grab_focus()


func _chip(text: String, parent: Node) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.theme_type_variation = &"Chip"
	b.custom_minimum_size = Vector2(200, 80)
	parent.add_child(b)
	return b


func _on_op_toggled(on: bool, op: int) -> void:
	if on:
		if op not in GameSettings.ops:
			GameSettings.ops.append(op)
	elif GameSettings.ops.size() <= 1:
		_op_buttons[op].set_pressed_no_signal(true) # keep at least one kind on
	else:
		GameSettings.ops.erase(op)


func _on_start() -> void:
	SaveData.remember_settings()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


## Landscape: card count and clock choice sit side by side so everything fits.
func _update_layout() -> void:
	%LengthAndClock.vertical = size.y > size.x
