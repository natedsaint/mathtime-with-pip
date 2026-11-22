class_name QuestionGenerator
extends RefCounted
## Makes questions for the chosen operations and level.
## - Subtraction never goes negative.
## - Division always has a whole-number answer (built from a multiplication).
## - Never the same question twice in a row; "freebies" (+0, ×1, ÷1) are rare.
## - Missed questions can be requeued so they come back a few cards later.

const LEVELS := {
	1: {"sum_max": 10, "table_max": 5, "factor_max": 10},
	2: {"sum_max": 20, "table_max": 10, "factor_max": 10},
	3: {"sum_max": 100, "table_max": 12, "factor_max": 12},
}
const RETRY_GAP := 3 # fresh cards shown before a missed one returns
const FREEBIE_CHANCE := 0.15

var ops: Array[int] = []
var level := 1
var rng := RandomNumberGenerator.new()
var _last_text := ""
var _retry_queue: Array[Question] = []
var _since_requeue := 0


func _init(p_ops: Array, p_level: int = 1, p_seed: int = -1) -> void:
	for op in p_ops:
		ops.append(int(op))
	if ops.is_empty():
		ops.append(Question.Op.ADD)
	level = clampi(p_level, 1, 3)
	if p_seed >= 0:
		rng.seed = p_seed
	else:
		rng.randomize()


func next() -> Question:
	var q: Question
	if not _retry_queue.is_empty() and _since_requeue >= RETRY_GAP and _retry_queue[0].text() != _last_text:
		q = _retry_queue.pop_front()
		_since_requeue = 0
	else:
		q = _fresh()
		_since_requeue += 1
	_last_text = q.text()
	return q


func requeue(q: Question) -> void:
	_retry_queue.append(q)
	_since_requeue = 0


func pending_retries() -> int:
	return _retry_queue.size()


func _fresh() -> Question:
	var q := _make()
	for i in 30:
		if q.text() != _last_text and (not _is_freebie(q) or rng.randf() < FREEBIE_CHANCE):
			break
		q = _make()
	return q


func _make() -> Question:
	var cfg: Dictionary = LEVELS[level]
	var op: int = ops[rng.randi_range(0, ops.size() - 1)]
	match op:
		Question.Op.ADD:
			var total := rng.randi_range(0, cfg["sum_max"])
			var a := rng.randi_range(0, total)
			return Question.new(a, total - a, op)
		Question.Op.SUB:
			var a := rng.randi_range(0, cfg["sum_max"])
			return Question.new(a, rng.randi_range(0, a), op)
		Question.Op.MUL:
			var table := rng.randi_range(1, cfg["table_max"])
			var factor := rng.randi_range(1, cfg["factor_max"])
			if rng.randf() < 0.5:
				return Question.new(table, factor, op)
			return Question.new(factor, table, op)
		_:
			var divisor := rng.randi_range(1, cfg["table_max"])
			var quotient := rng.randi_range(1, cfg["factor_max"])
			return Question.new(divisor * quotient, divisor, Question.Op.DIV)


func _is_freebie(q: Question) -> bool:
	match q.op:
		Question.Op.ADD:
			return q.a == 0 or q.b == 0
		Question.Op.SUB:
			return q.b == 0 or q.a == q.b
		Question.Op.MUL:
			return q.a <= 1 or q.b <= 1
		_:
			return q.b == 1 or q.answer == 1
