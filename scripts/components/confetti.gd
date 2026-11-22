class_name Confetti
extends Control
## Pixel confetti drawn on top of a screen. Pieces are little squares and strips
## that "flip" as they flutter down (their width squashes back and forth).
##   pop(point, count)  - burst from a point (local coordinates)
##   rain(seconds)      - fall from the top of the screen for a while

const COLORS: Array[Color] = [
	Color("ffd23f"), Color("ff8c42"), Color("ff9eb5"), Color("9be7c4"),
	Color("a5d8ff"), Color("c9c1ff"), Color("5a85f5"),
]
const GRAVITY := 1300.0
const MAX_FALL := 320.0
const PIXEL := 8.0

var _pieces: Array[Dictionary] = []
var _rain_left := 0.0
var _rain_rate := 0.0
var _rain_accum := 0.0
var _time := 0.0
var _drawn_any := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func pop(at: Vector2, count := 40, power := 750.0) -> void:
	for i in count:
		var angle := randf_range(-PI * 0.95, -PI * 0.05) # mostly upward
		var speed := randf_range(0.35, 1.0) * power
		_spawn(at, Vector2.from_angle(angle) * speed)


func rain(seconds := 2.5, per_second := 90.0) -> void:
	_rain_left = seconds
	_rain_rate = per_second


func _spawn(at: Vector2, velocity: Vector2) -> void:
	var strip := randf() < 0.4
	_pieces.append({
		"pos": at,
		"vel": velocity,
		"size": Vector2(PIXEL * 2, PIXEL) if strip else Vector2(PIXEL * 1.5, PIXEL * 1.5),
		"color": COLORS[randi() % COLORS.size()],
		"spin": randf() * TAU,
		"spin_speed": randf_range(6.0, 14.0),
		"sway": randf_range(20.0, 60.0),
		"phase": randf() * TAU,
	})


func _process(delta: float) -> void:
	_time += delta
	if _rain_left > 0.0:
		_rain_left -= delta
		_rain_accum += _rain_rate * delta
		while _rain_accum >= 1.0:
			_rain_accum -= 1.0
			_spawn(Vector2(randf() * size.x, -20.0), Vector2(randf_range(-60, 60), randf_range(80, 220)))
	if _pieces.is_empty():
		if _drawn_any:
			_drawn_any = false
			queue_redraw() # clear the last frame once
		return
	_drawn_any = true
	for p in _pieces:
		var vel: Vector2 = p["vel"]
		vel.y = minf(vel.y + GRAVITY * delta, MAX_FALL)
		vel.x *= pow(0.25, delta) # air resistance
		p["vel"] = vel
		p["pos"] += vel * delta + Vector2(sin(_time * 3.0 + p["phase"]) * p["sway"] * delta, 0.0)
		p["spin"] += p["spin_speed"] * delta
	_pieces = _pieces.filter(func(p: Dictionary) -> bool: return p["pos"].y < size.y + 30.0)
	queue_redraw()


func _draw() -> void:
	for p in _pieces:
		var s: Vector2 = p["size"]
		var w := maxf(roundf(s.x * absf(cos(p["spin"])) / 2.0) * 2.0, 2.0) # flip, in whole pixels
		var pos: Vector2 = p["pos"]
		var color: Color = p["color"]
		if cos(p["spin"]) < 0.0:
			color = color.darkened(0.18) # back side is a bit darker
		draw_rect(Rect2((pos - Vector2(w, s.y) / 2.0).round(), Vector2(w, s.y)), color)
