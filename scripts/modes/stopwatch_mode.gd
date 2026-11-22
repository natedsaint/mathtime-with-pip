class_name StopwatchMode
extends ModeBase
## Mode B: finish a fixed number of cards; the clock counts up.
## Every card must be answered correctly (missed ones come back), so times are comparable.

var total: int


func _init(p_total: int) -> void:
	total = p_total


func is_finished() -> bool:
	return correct >= total


func shows_timer() -> bool:
	return true


func timer_text() -> String:
	return format_time(elapsed)


func progress_text() -> String:
	return "Card %d of %d" % [mini(correct + 1, total), total]
