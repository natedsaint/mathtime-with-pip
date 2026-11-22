class_name ModeBase
extends RefCounted
## Shared rules for a game mode. The game screen is the same for every mode;
## it asks the mode what to show and when the game is over.

var correct := 0 # cards answered correctly
var answered := 0 # cards finished (correct, or answer shown)
var first_try := 0
var streak := 0 # first-try correct answers in a row
var best_streak := 0
var elapsed := 0.0 # seconds of play (paused during feedback)


func tick(delta: float) -> void:
	elapsed += delta


func on_correct(was_first_try: bool) -> void:
	correct += 1
	answered += 1
	if was_first_try:
		first_try += 1
		streak += 1
		best_streak = maxi(best_streak, streak)


func on_miss() -> void:
	streak = 0


func on_revealed() -> void:
	answered += 1


func is_finished() -> bool:
	return false


func shows_timer() -> bool:
	return false


func timer_text() -> String:
	return ""


func timer_urgent() -> bool:
	return false


func progress_text() -> String:
	return "%d right" % correct


func quit_label() -> String:
	return "Pause"


func result() -> Dictionary:
	return {"correct": correct, "answered": answered, "first_try": first_try,
		"best_streak": best_streak, "elapsed": elapsed}


@warning_ignore("integer_division")
static func format_time(seconds: float) -> String:
	var tenths := int(seconds * 10.0)
	return "%d:%02d.%d" % [tenths / 600, (tenths / 10) % 60, tenths % 10]
