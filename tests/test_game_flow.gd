extends SceneTree
## Plays real games through the game screen (no window needed).
## Run: godot --headless --path . --script res://tests/test_game_flow.gd

const TEST_SAVE := "user://test_progress.cfg"

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_data := root.get_node("SaveData")
	var settings := root.get_node("GameSettings")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	save_data.path = TEST_SAVE
	save_data.cfg = ConfigFile.new()

	# Stopwatch, 5 cards, one card answered wrong 3 times (revealed, then must come back).
	settings.mode = settings.Mode.STOPWATCH
	settings.question_count = 5
	settings.ops.assign([Question.Op.MUL, Question.Op.DIV])
	settings.level = 2
	var r := await _play(true)
	check(r.get("correct") == 5, "stopwatch finishes after 5 correct, got %s" % r)
	check(r.get("answered") == 6, "revealed card counted as answered: %s" % r)
	check(r.get("is_best") == true and r.get("previous_best") == -1.0, "first run is a best: %s" % r)
	check(r.get("elapsed") > 0.0, "time recorded")
	var r2 := await _play(false)
	check(r2.get("previous_best") == r.get("elapsed"), "second run compares to first: %s" % r2)

	# Countdown ends by itself when the clock runs out.
	settings.mode = settings.Mode.COUNTDOWN
	settings.duration_sec = 1
	var r3 := await _play(false, 2) # answer two, then let the clock run out
	check(r3.get("mode") == settings.Mode.COUNTDOWN and r3.get("correct") == 2, "countdown result: %s" % r3)
	check(r3.get("is_best") == true and r3.get("duration") == 1.0, "countdown record: %s" % r3)

	await _test_pip_easter_egg(settings)
	await _test_hidden_clock_still_times(settings)
	await _test_three_tries_before_reveal(settings)
	await _test_pause_stops_clock(settings)
	await _test_records_screen(save_data)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("All game flow tests passed." if failures == 0 else "%d failure(s)." % failures)
	quit(1 if failures > 0 else 0)


## Plays the game screen until it moves to Results; returns the saved result.
func _play(miss_first_card: bool, max_answers := 1000) -> Dictionary:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var missed := not miss_first_card
	var answers := 0
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != null and current_scene.name == "Results":
			break
		if not is_instance_valid(game) or current_scene != game:
			continue # scene change in progress
		if game.state == game.State.REVEAL:
			game._on_submit() # "Got it"
		elif game.state == game.State.INPUT and answers < max_answers and game.answer_text.is_empty():
			answers += 1
			var answer: int = game.question.answer
			if not missed:
				answer += 1
				if game.misses == game.MAX_TRIES - 1:
					missed = true # this wrong answer is the last try, so Pip reveals
			for ch in str(answer):
				game._on_digit(int(ch))
			game._on_submit()
	check(current_scene != null and current_scene.name == "Results", "ended on Results screen")
	if current_scene != null:
		current_scene.free()
		current_scene = null
	return root.get_node("GameSettings").last_result


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("FAIL: ", msg)


func _test_pause_stops_clock(settings: Node) -> void:
	settings.mode = settings.Mode.STOPWATCH
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await _wait(0.2)
	game._set_paused(true)
	var frozen: float = game.mode.elapsed
	await _wait(0.3)
	check(game.mode.elapsed == frozen, "clock stopped while paused")
	check(game.get_node("%PauseOverlay").visible, "pause menu shown")
	check(game.get_node("%CardVBox").modulate.a == 0.0, "card hidden while paused")
	game._on_digit(5)
	check(game.answer_text == "", "keypad ignored while paused")
	game._set_paused(false)
	await _wait(0.2)
	check(game.mode.elapsed > frozen, "clock runs again after resume")
	game.free()

	settings.mode = settings.Mode.PRACTICE
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._set_paused(true)
	check(not game.paused, "practice mode has no pause (no clock)")
	game.free()


func _test_records_screen(save_data: Node) -> void:
	var sw: Array = save_data.get_records("stopwatch")
	check(sw.size() == 1 and sw[0]["history"].size() == 2, "stopwatch records: %s" % [sw])
	var info: Dictionary = save_data.describe_key("add-mul_L2_n20")
	check(info["ops"] == "+  ×" and info["level"] == 2 and info["length"] == "20 cards", "describe_key: %s" % info)
	check(save_data.describe_key("sub_L1_t60")["length"] == "1 min", "duration label")
	var screen: Node = load("res://scenes/records.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	check(screen.get_node("%List").get_child_count() >= 1, "records listed")
	screen.free()


func _wait(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < end:
		await process_frame


func _test_three_tries_before_reveal(settings: Node) -> void:
	settings.mode = settings.Mode.PRACTICE
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var wrong := str(game.question.answer + 1)
	for attempt in 3:
		for ch in wrong:
			game._on_digit(int(ch))
		game._on_submit()
		if attempt < 2:
			check(game.state == game.State.INPUT, "still answering after %d wrong" % (attempt + 1))
			check(game.answer_text == "", "answer box cleared after a wrong try")
	check(game.state == game.State.REVEAL, "Pip reveals after 3 wrong answers")
	check(game.get_node("%Pip")._mood == "help", "Pip shows the answer on his screen")
	game.free()


func _test_hidden_clock_still_times(settings: Node) -> void:
	settings.mode = settings.Mode.STOPWATCH
	settings.show_clock = false
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await _wait(0.2)
	check(not game.get_node("%TimerLabel").visible, "clock hidden when show_clock is off")
	check(game.mode.elapsed > 0.0, "run is still timed with the clock hidden")
	game.free()
	settings.show_clock = true
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.get_node("%TimerLabel").visible, "clock shown when show_clock is on")
	game.free()
	settings.mode = settings.Mode.COUNTDOWN
	settings.show_clock = false
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.get_node("%TimerLabel").visible, "countdown always shows its clock")
	game.free()
	settings.show_clock = true


func _test_pip_easter_egg(settings: Node) -> void:
	settings.mode = settings.Mode.PRACTICE
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var pip: Pip = game.get_node("%Pip")
	var clicked := InputEventMouseButton.new()
	clicked.button_index = MOUSE_BUTTON_LEFT
	clicked.pressed = true
	pip._gui_input(clicked)
	check(pip._mood == "love" and pip.face == "love", "one tap: heart eyes")
	check(game.get_node("%Bubble")._label.text in game.GIGGLES, "Pip giggles in the bubble")
	for i in 4:
		pip.poke()
	check(pip._mood == "dizzy", "five quick taps: dizzy")
	check(game.get_node("%Bubble")._label.text == game.DIZZY_LINE, "dizzy line in the bubble")
	pip.poke() # within DIZZY_COOLDOWN: ignored
	check(pip._mood == "dizzy", "taps ignored right after getting dizzy")
	check(game.get_node("%Bubble")._label.text == game.DIZZY_LINE, "bubble keeps the dizzy line")
	await _wait(2.6)
	check(pip._mood == "idle" and is_equal_approx(pip.tilt, 0.0), "Pip recovers upright")
	# While Pip shows an answer, a tap must not wipe the number off his screen.
	pip.show_number(42)
	pip.poke()
	check(pip._mood == "help" and not pip._number_cols.is_empty(), "answer stays on screen when tapped")
	check(game.state == game.State.INPUT, "tapping Pip doesn't change the game")
	game.free()
