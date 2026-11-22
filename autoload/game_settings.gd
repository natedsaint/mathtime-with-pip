extends Node
## Holds the choices made on the Setup screen and hands them to the game,
## plus the result of the last game for the Results screen.

enum Mode { PRACTICE, STOPWATCH, COUNTDOWN }

const MODE_TITLES := {
	Mode.PRACTICE: "Practice",
	Mode.STOPWATCH: "Beat Your Time",
	Mode.COUNTDOWN: "Countdown",
}
const COUNT_OPTIONS: Array[int] = [10, 20, 30]
const DURATION_OPTIONS: Array[int] = [30, 60, 120]
const LEVEL_NAMES := ["Starter", "Builder", "Pro"]

var mode: Mode = Mode.PRACTICE
var ops: Array[int] = [Question.Op.ADD]
var level := 1
var question_count := 20
var duration_sec := 60
var show_clock := true # Beat Your Time: show the running clock (it always times you)
var last_result: Dictionary = {}


@warning_ignore("integer_division")
static func duration_label(seconds: int) -> String:
	if seconds % 60 == 0:
		return "%d min" % (seconds / 60)
	return "%d sec" % seconds


## Records are kept per settings combo, e.g. "add-mul_L2_n20".
func record_key() -> String:
	var sorted := ops.duplicate()
	sorted.sort()
	var names := PackedStringArray()
	for op in sorted:
		names.append(Question.NAMES[op])
	var key := "%s_L%d" % ["-".join(names), level]
	match mode:
		Mode.STOPWATCH:
			key += "_n%d" % question_count
		Mode.COUNTDOWN:
			key += "_t%d" % duration_sec
	return key
