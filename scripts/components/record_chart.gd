class_name RecordChart
extends Control
## Tiny pixel-style bar chart of recent tries. Taller bar = better try
## (faster time, or more right). The best try is gold.

const BAR_COLOR := Color("a5c0fa")
const BEST_COLOR := Color("ffd23f")
const BASE_COLOR := Color("d9dce6")
const MAX_BARS := 10

var values: Array = []
var lower_is_better := false


func setup(p_values: Array, p_lower_is_better: bool) -> void:
	values = p_values.slice(-MAX_BARS)
	lower_is_better = p_lower_is_better
	queue_redraw()


func _draw() -> void:
	if values.is_empty():
		return
	var scores: Array[float] = []
	for v in values:
		var f := float(v)
		scores.append((1.0 / maxf(f, 0.1)) if lower_is_better else f)
	var top := 0.0
	for s in scores:
		top = maxf(top, s)
	var gap := 4.0
	var bar_w := floorf((size.x - gap * (MAX_BARS - 1)) / MAX_BARS)
	var best_i := scores.find(top)
	draw_rect(Rect2(0, size.y - 4, size.x, 4), BASE_COLOR)
	for i in scores.size():
		var h := 6.0 if top <= 0.0 else maxf(roundf((size.y - 8) * scores[i] / top), 6.0)
		var x := i * (bar_w + gap)
		draw_rect(Rect2(x, size.y - 4 - h, bar_w, h), BEST_COLOR if i == best_i else BAR_COLOR)
