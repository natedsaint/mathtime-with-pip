extends Node
## Saves best times/scores, recent history, and the last settings used.

const PATH := "user://progress.cfg"
const HISTORY_LEN := 10

var path := PATH # tests point this somewhere else
var cfg := ConfigFile.new()


func _ready() -> void:
	cfg.load(path) # Missing file on first run is fine.
	_apply_last_settings()


func save() -> void:
	cfg.save(path)


func remember_settings() -> void:
	cfg.set_value("last", "ops", GameSettings.ops)
	cfg.set_value("last", "level", GameSettings.level)
	cfg.set_value("last", "question_count", GameSettings.question_count)
	cfg.set_value("last", "duration_sec", GameSettings.duration_sec)
	cfg.set_value("last", "show_clock", GameSettings.show_clock)
	save()


## Lower time is better. Returns {"previous_best": float (-1 if none), "is_best": bool}.
func record_stopwatch(key: String, seconds: float) -> Dictionary:
	var prev := float(cfg.get_value("stopwatch_best", key, -1.0))
	var is_best := prev < 0.0 or seconds < prev
	if is_best:
		cfg.set_value("stopwatch_best", key, seconds)
	_push_history("stopwatch_history", key, seconds)
	save()
	return {"previous_best": prev, "is_best": is_best}


## Higher score is better. Returns {"previous_best": int (-1 if none), "is_best": bool}.
func record_countdown(key: String, score: int) -> Dictionary:
	var prev := int(cfg.get_value("countdown_best", key, -1))
	var is_best := prev < 0 or score > prev
	if is_best:
		cfg.set_value("countdown_best", key, score)
	_push_history("countdown_history", key, score)
	save()
	return {"previous_best": prev, "is_best": is_best}


## All records for "stopwatch" or "countdown", most recently played first.
## Each: {"key", "best", "history": [values, oldest first], "last_played"}
func get_records(kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var section := kind + "_best"
	if not cfg.has_section(section):
		return out
	for key in cfg.get_section_keys(section):
		var history: Array = cfg.get_value(kind + "_history", key, [])
		var values := []
		for h in history:
			values.append(h["value"])
		out.append({
			"key": key,
			"best": cfg.get_value(section, key),
			"history": values,
			"last_played": history[-1]["time"] if not history.is_empty() else 0.0,
		})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["last_played"] > b["last_played"])
	return out


## Turns a record key like "add-mul_L2_n20" into readable parts.
static func describe_key(key: String) -> Dictionary:
	var parts := key.split("_")
	var symbols := PackedStringArray()
	for op_name in parts[0].split("-"):
		var op: int = Question.NAMES.find_key(op_name)
		symbols.append(Question.SYMBOLS[op])
	var level := int(parts[1].substr(1))
	var length := ""
	if parts.size() > 2:
		var n := int(parts[2].substr(1))
		length = "%d cards" % n if parts[2].begins_with("n") else GameSettings.duration_label(n)
	return {"ops": "  ".join(symbols), "level": level,
		"level_name": GameSettings.LEVEL_NAMES[clampi(level - 1, 0, 2)], "length": length}


func _push_history(section: String, key: String, value: Variant) -> void:
	var history: Array = cfg.get_value(section, key, [])
	history.append({"value": value, "time": Time.get_unix_time_from_system()})
	while history.size() > HISTORY_LEN:
		history.pop_front()
	cfg.set_value(section, key, history)


func _apply_last_settings() -> void:
	var ops: Variant = cfg.get_value("last", "ops", []) if cfg.has_section_key("last", "ops") else []
	if ops is Array and not ops.is_empty():
		GameSettings.ops.clear()
		for op in ops:
			GameSettings.ops.append(int(op))
	GameSettings.level = int(cfg.get_value("last", "level", GameSettings.level))
	GameSettings.question_count = int(cfg.get_value("last", "question_count", GameSettings.question_count))
	GameSettings.duration_sec = int(cfg.get_value("last", "duration_sec", GameSettings.duration_sec))
	GameSettings.show_clock = bool(cfg.get_value("last", "show_clock", GameSettings.show_clock))
