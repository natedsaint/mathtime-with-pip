extends Control
## The flashcard screen, shared by all three modes. The mode object decides
## what the HUD shows and when the game ends.

enum State { INPUT, FEEDBACK, REVEAL, DONE }

const CHEERS := ["Nice!", "You got it!", "Great job!", "Math wizard!", "Awesome!",
	"Yes!", "Super!", "Way to go!", "Brilliant!", "Nailed it!"]
const TRY_AGAIN := ["Hmm, let's try again!", "So close! Try again!",
	"Give it another go!", "Take your time, try again!"]
const GIGGLES := ["Hee hee! That tickles!", "Beep boop!", "Hi there!", "Boing!", "Hee hee!"]
const DIZZY_LINE := "Whoa… so dizzy!"
const LAST_TRY := "One more try! You've got this!"
const MAX_TRIES := 3 # wrong answers before Pip shows the answer
const STREAK_EVERY := 5
const MAX_DIGITS := 4
const FEEDBACK_DELAY := 0.7

const COLOR_INK := Color(0.2, 0.22, 0.3)
const COLOR_PLACEHOLDER := Color(0.2, 0.22, 0.3, 0.22)
const COLOR_GOOD := Color(0.18, 0.6, 0.35)
const COLOR_GENTLE := Color(0.45, 0.4, 0.68) # soft purple for "try again", never red
const COLOR_TIMER := Color(0.2, 0.22, 0.3)
const COLOR_TIMER_URGENT := Color(0.95, 0.55, 0.15)

var mode: ModeBase
var generator: QuestionGenerator
var question: Question
var answer_text := ""
var misses := 0
var state := State.INPUT
var paused := false
var _last_lines := {}


func _ready() -> void:
	generator = QuestionGenerator.new(GameSettings.ops, GameSettings.level)
	mode = _make_mode()
	%QuitButton.text = mode.quit_label()
	%QuitButton.pressed.connect(_on_quit)
	# Beat Your Time can hide its clock (it still times the run for records).
	%TimerLabel.visible = mode.shows_timer() and \
		(GameSettings.mode != GameSettings.Mode.STOPWATCH or GameSettings.show_clock)
	%NumberPad.digit_pressed.connect(_on_digit)
	%NumberPad.backspace_pressed.connect(_on_backspace)
	%NumberPad.submit_pressed.connect(_on_submit)
	%Pip.poked.connect(_on_pip_poked)
	%ResumeButton.pressed.connect(_set_paused.bind(false))
	%RestartButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game.tscn"))
	%MenuButton.pressed.connect(func() -> void:
		state = State.DONE
		get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))
	resized.connect(_update_layout)
	_update_layout()
	%Pip.wave(1.5)
	_say("Let's go!", COLOR_INK)
	_next_question()


func _make_mode() -> ModeBase:
	match GameSettings.mode:
		GameSettings.Mode.STOPWATCH:
			return StopwatchMode.new(GameSettings.question_count)
		GameSettings.Mode.COUNTDOWN:
			return CountdownMode.new(GameSettings.duration_sec)
	return PracticeMode.new()


func _process(delta: float) -> void:
	# The clock only runs while the player is answering, not during cheers or reveals.
	if state == State.INPUT and not paused:
		mode.tick(delta)
		if mode.is_finished():
			_finish()
			return
	_update_hud()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or state == State.DONE:
		return
	if key.keycode == KEY_ESCAPE and mode.shows_timer():
		_set_paused(not paused)
		get_viewport().set_input_as_handled()
		return
	if paused:
		return # let the pause menu buttons handle keys
	if key.unicode >= 48 and key.unicode <= 57:
		_on_digit(key.unicode - 48)
	elif key.keycode == KEY_BACKSPACE or key.keycode == KEY_DELETE:
		_on_backspace()
	elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		_on_submit()
	else:
		return
	get_viewport().set_input_as_handled()


# --- Input -------------------------------------------------------------------

func _on_digit(digit: int) -> void:
	if paused or state != State.INPUT or answer_text.length() >= MAX_DIGITS:
		return
	if answer_text == "0":
		answer_text = ""
	answer_text += str(digit)
	Audio.play("tap")
	_refresh_answer(COLOR_INK)


func _on_backspace() -> void:
	if paused or state != State.INPUT:
		return
	if not answer_text.is_empty():
		Audio.play("tap")
	answer_text = answer_text.left(-1)
	_refresh_answer(COLOR_INK)


func _on_submit() -> void:
	if paused:
		return
	match state:
		State.INPUT:
			_check_answer()
		State.REVEAL:
			_say("", COLOR_INK)
			%Pip.idle()
			_next_question()


# --- Game flow ---------------------------------------------------------------

func _check_answer() -> void:
	if answer_text.is_empty():
		return
	if answer_text.to_int() == question.answer:
		_on_correct()
	else:
		_on_wrong()


func _on_correct() -> void:
	var first_try := misses == 0
	mode.on_correct(first_try)
	_refresh_answer(COLOR_GOOD)
	if first_try and mode.streak % STREAK_EVERY == 0:
		_say("%d in a row!!" % mode.streak, COLOR_GOOD)
		%Pip.celebrate()
		%Confetti.pop(%Card.get_global_rect().get_center(), 80, 1000.0)
		Audio.play("streak")
	else:
		_say(_pick("cheer", CHEERS), COLOR_GOOD)
		%Pip.cheer()
		%Confetti.pop(%AnswerBox.get_global_rect().get_center(), 14, 520.0)
		Audio.play("correct")
	state = State.FEEDBACK
	get_tree().create_timer(FEEDBACK_DELAY).timeout.connect(_after_feedback)


func _after_feedback() -> void:
	if state != State.FEEDBACK:
		return
	if mode.is_finished():
		_finish()
	else:
		_next_question()


func _on_wrong() -> void:
	misses += 1
	mode.on_miss()
	if misses >= MAX_TRIES:
		_reveal()
	else:
		Audio.play("try_again")
		_say(LAST_TRY if misses == MAX_TRIES - 1 else _pick("try", TRY_AGAIN), COLOR_GENTLE)
		%Pip.think()
		answer_text = ""
		_refresh_answer(COLOR_INK)


## After MAX_TRIES misses, kindly show the answer. The card comes back later.
func _reveal() -> void:
	state = State.REVEAL
	mode.on_revealed()
	generator.requeue(question)
	_say("It's %d! We'll try it again soon." % question.answer, COLOR_GENTLE)
	%Pip.show_number(question.answer)
	Audio.play("reveal")
	answer_text = str(question.answer)
	_refresh_answer(COLOR_GENTLE)
	%NumberPad.set_submit_text("Got it")


func _next_question() -> void:
	question = generator.next()
	misses = 0
	answer_text = ""
	state = State.INPUT
	%QuestionLabel.text = question.text() + " ="
	%NumberPad.set_submit_text("OK")
	_refresh_answer(COLOR_INK)
	_pop_card()


func _finish() -> void:
	if state == State.DONE:
		return
	state = State.DONE
	var result := mode.result()
	result["mode"] = GameSettings.mode
	match GameSettings.mode:
		GameSettings.Mode.STOPWATCH:
			result.merge(SaveData.record_stopwatch(GameSettings.record_key(), mode.elapsed))
		GameSettings.Mode.COUNTDOWN:
			result.merge(SaveData.record_countdown(GameSettings.record_key(), mode.correct))
	GameSettings.last_result = result
	get_tree().change_scene_to_file("res://scenes/results.tscn")


func _on_quit() -> void:
	if GameSettings.mode == GameSettings.Mode.PRACTICE:
		_finish()
	else:
		_set_paused(true)


## Pausing stops the clock and hides the card (no peeking while paused).
func _set_paused(on: bool) -> void:
	if on and (state == State.DONE or not mode.shows_timer()):
		return
	paused = on
	%PauseOverlay.visible = on
	%CardVBox.modulate.a = 0.0 if on else 1.0
	if on:
		%PausePip.wave(1.5)
		%ResumeButton.grab_focus()


## Timed games pause themselves if you switch away from the app.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_node_ready() and not paused:
			_set_paused(true)


## Easter egg: Pip talks back when tapped, but never over a cheer or a hint.
func _on_pip_poked(dizzy: bool) -> void:
	if state == State.INPUT and not paused:
		_say(DIZZY_LINE if dizzy else _pick("giggle", GIGGLES), COLOR_INK)


# --- Presentation ------------------------------------------------------------

func _update_hud() -> void:
	%ProgressLabel.text = mode.progress_text()
	%StreakLabel.text = "%d in a row" % mode.streak if mode.streak >= 2 else ""
	if mode.shows_timer():
		%TimerLabel.text = mode.timer_text()
		%TimerLabel.add_theme_color_override("font_color",
			COLOR_TIMER_URGENT if mode.timer_urgent() else COLOR_TIMER)


func _update_layout() -> void:
	var portrait := size.y > size.x
	%Body.vertical = portrait # keypad goes under the card
	# Squarer screens (like iPad's 4:3) have spare room: grow the keypad and Pip into it.
	var grow := clampf(minf(size.x / 720.0, size.y / 1280.0) if portrait else size.y / 720.0, 1.0, 1.4)
	%NumberPad.set_key_size((Vector2(190, 104) if portrait else NumberPad.KEY_SIZE) * grow, grow)
	var pip_px := floorf(7.0 * grow)
	%Pip.custom_minimum_size = Vector2(Pip.W, Pip.H) * pip_px
	%QuestionLabel.add_theme_font_size_override("font_size", 96 if portrait else 128)


func _refresh_answer(color: Color) -> void:
	%AnswerLabel.text = answer_text if not answer_text.is_empty() else "?"
	%AnswerLabel.add_theme_color_override("font_color",
		color if not answer_text.is_empty() else COLOR_PLACEHOLDER)


func _say(text: String, color: Color) -> void:
	%Bubble.say(text, color)


func _pop_card() -> void:
	var card: Control = %Card
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2.ONE * 0.92
	card.modulate.a = 0.0
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "scale", Vector2.ONE, 0.28)
	t.tween_property(card, "modulate:a", 1.0, 0.18)


## Random line from a pool, never the same one twice in a row.
func _pick(pool_name: String, pool: Array) -> String:
	var i := randi() % pool.size()
	if pool.size() > 1 and i == _last_lines.get(pool_name, -1):
		i = (i + 1) % pool.size()
	_last_lines[pool_name] = i
	return pool[i]
