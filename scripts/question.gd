class_name Question
extends RefCounted
## One flashcard: a OP b = answer.

enum Op { ADD, SUB, MUL, DIV }

const SYMBOLS := {Op.ADD: "+", Op.SUB: "−", Op.MUL: "×", Op.DIV: "÷"}
const NAMES := {Op.ADD: "add", Op.SUB: "sub", Op.MUL: "mul", Op.DIV: "div"}

var a: int
var b: int
var op: int
var answer: int


@warning_ignore("integer_division")
func _init(p_a: int, p_b: int, p_op: int) -> void:
	a = p_a
	b = p_b
	op = p_op
	match op:
		Op.ADD:
			answer = a + b
		Op.SUB:
			answer = a - b
		Op.MUL:
			answer = a * b
		Op.DIV:
			answer = a / b


func text() -> String:
	return "%d %s %d" % [a, SYMBOLS[op], b]


func full_text() -> String:
	return "%s = %d" % [text(), answer]
