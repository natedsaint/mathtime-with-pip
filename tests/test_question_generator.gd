extends SceneTree
## Run: godot --headless --path . --script res://tests/test_question_generator.gd

var failures := 0


func _initialize() -> void:
	_test_rules_hold_for_every_level_and_op()
	_test_no_back_to_back_repeats()
	_test_requeued_question_comes_back()
	_test_mixed_ops_all_appear()
	_test_format_time()
	if failures == 0:
		print("All question generator tests passed.")
	else:
		printerr("%d failure(s)." % failures)
	quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("FAIL: ", msg)


func _test_rules_hold_for_every_level_and_op() -> void:
	for level in [1, 2, 3]:
		var limits: Dictionary = QuestionGenerator.LEVELS[level]
		for op in [Question.Op.ADD, Question.Op.SUB, Question.Op.MUL, Question.Op.DIV]:
			var gen := QuestionGenerator.new([op], level, 1234)
			for i in 2000:
				var q := gen.next()
				var tag := "L%d %s" % [level, q.text()]
				check(q.op == op, tag + " wrong op")
				check(q.answer >= 0, tag + " negative answer")
				match op:
					Question.Op.ADD:
						check(q.a + q.b == q.answer and q.answer <= limits["sum_max"], tag + " add out of range")
					Question.Op.SUB:
						check(q.a - q.b == q.answer and q.a <= limits["sum_max"], tag + " sub out of range")
					Question.Op.MUL:
						check(q.a * q.b == q.answer and mini(q.a, q.b) <= limits["table_max"], tag + " mul out of range")
					Question.Op.DIV:
						check(q.b > 0 and q.a % q.b == 0 and q.b * q.answer == q.a, tag + " div not whole")
						check(q.b <= limits["table_max"] and q.answer <= limits["factor_max"], tag + " div out of range")


func _test_no_back_to_back_repeats() -> void:
	var gen := QuestionGenerator.new([Question.Op.ADD], 1, 99)
	var last := ""
	for i in 3000:
		var t := gen.next().text()
		check(t != last, "repeat in a row: " + t)
		last = t


func _test_requeued_question_comes_back() -> void:
	var gen := QuestionGenerator.new([Question.Op.MUL], 2, 7)
	var missed := gen.next()
	gen.requeue(missed)
	var seen_at := -1
	for i in 10:
		if gen.next() == missed:
			seen_at = i
			break
	check(seen_at == QuestionGenerator.RETRY_GAP, "requeued card returned at %d" % seen_at)
	check(gen.pending_retries() == 0, "retry queue not emptied")


func _test_mixed_ops_all_appear() -> void:
	var all := [Question.Op.ADD, Question.Op.SUB, Question.Op.MUL, Question.Op.DIV]
	var gen := QuestionGenerator.new(all, 2, 5)
	var seen := {}
	for i in 200:
		seen[gen.next().op] = true
	check(seen.size() == 4, "not all ops appeared: %s" % [seen.keys()])


func _test_format_time() -> void:
	check(ModeBase.format_time(0.0) == "0:00.0", "format 0")
	check(ModeBase.format_time(102.37) == "1:42.3", "format 102.37 -> " + ModeBase.format_time(102.37))
