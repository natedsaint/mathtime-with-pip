extends Control


func _ready() -> void:
	%PlayButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))
	%RecordsButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/records.tscn"))
	%PlayButton.grab_focus()
	# The title gets the full screen width (minus a margin) and shrinks to fit it.
	resized.connect(_fit_title)
	_fit_title()
	%Pip.wave()
	%SoundButton.button_pressed = not Audio.muted
	_update_sound_label()
	%SoundButton.toggled.connect(func(on: bool) -> void:
		Audio.set_muted(not on)
		_update_sound_label()
		Audio.play("correct"))
	var timer := Timer.new()
	timer.wait_time = 6.0
	timer.timeout.connect(func() -> void: %Pip.wave())
	add_child(timer)
	timer.start()


func _update_sound_label() -> void:
	%SoundButton.text = "Sound on" if not Audio.muted else "Sound off"


func _fit_title() -> void:
	%TitleLabel.custom_minimum_size.x = size.x - 64.0
