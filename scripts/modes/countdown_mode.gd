class_name CountdownMode
extends ModeBase
## Mode C: answer as many as you can before the clock runs out.

const URGENT_SECONDS := 10.0

var duration: float


func _init(p_duration: float) -> void:
	duration = p_duration


func tick(delta: float) -> void:
	elapsed = minf(elapsed + delta, duration)


func remaining() -> float:
	return duration - elapsed


func is_finished() -> bool:
	return elapsed >= duration


func shows_timer() -> bool:
	return true


@warning_ignore("integer_division")
func timer_text() -> String:
	var s := int(ceil(remaining()))
	return "%d:%02d" % [s / 60, s % 60]


func timer_urgent() -> bool:
	return remaining() <= URGENT_SECONDS


func result() -> Dictionary:
	var r := super()
	r["duration"] = duration
	return r
