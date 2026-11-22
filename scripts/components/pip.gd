class_name Pip
extends Control

signal poked(dizzy: bool)
## Pip the calc-bot. Drawn from the pixel grids below, so the art is easy to tweak:
## each character is one pixel (see COLORS). His screen is drawn as its own layer,
## which lets it change color with his mood and show faces or numbers.
##
## Moods: idle(), cheer(), celebrate(), think(), show_number(n), wave()
## Easter egg: tap Pip for a giggle; tap him 5 times fast and he gets dizzy.

const W := 18 # grid width in pixels
const H := 19 # grid height in pixels
const INK := Color("2b2d42")
const COLORS := {
	"k": Color("2b2d42"), # outline
	"m": Color("b8c0cc"), # metal body
	"G": Color("5c6370"), # dark buttons / feet
	"o": Color("ff8c42"), # orange antenna + buttons
}

## "S" marks the screen; it's filled separately with the mood color.
const BODY: Array[String] = [
	".......kkkk.......",
	".......kook.......",
	".......kkkk.......",
	"........kk........",
	"..kkkkkkkkkkkkkk..",
	"..kmmmmmmmmmmmmk..",
	"..kmkkkkkkkkkkmk..",
	"..kmkSSSSSSSSkmk..",
	"..kmkSSSSSSSSkmk..",
	"..kmkSSSSSSSSkmk..",
	"..kmkSSSSSSSSkmk..",
	"..kmkSSSSSSSSkmk..",
	"..kmkSSSSSSSSkmk..",
	"..kmkkkkkkkkkkmk..",
	"..kmmmmmmmmmmmmk..",
	"..kmGmGmGmGmoomk..",
	"..kmmmmmmmmmmmmk..",
	"..kkkkkkkkkkkkkk..",
	"....kGk....kGk....",
]
const SCREEN_POS := Vector2i(5, 7)
const SCREEN_W := 8
const SCREEN_H := 6

## Screen color for each mood. Celebrate cycles through a rainbow instead.
const SCREEN_COLORS := {
	"idle": Color("9be7c4"), # mint
	"happy": Color("ffe066"), # sunny yellow
	"think": Color("c9c1ff"), # soft lavender, never red
	"help": Color("1d2b4a"), # dark, like a calculator display
	"love": Color("ffc2d4"), # blushing pink (easter egg)
}
const DIGIT_COLOR := Color("a5d8ff") # glowing sky-blue digits on the dark screen

## Faces are 8x6 to fit the screen. The bottom row stays blank so the smile reads clearly.
const FACES := {
	"happy": [
		"........",
		"..k..k..",
		"..k..k..",
		".k....k.",
		"..kkkk..",
		"........",
	],
	"happy_blink": [
		"........",
		"........",
		".kk..kk.",
		".k....k.",
		"..kkkk..",
		"........",
	],
	"joy": [
		"........",
		"..k..k..",
		"........",
		".kkkkkk.",
		"..kkkk..",
		"........",
	],
	"think": [
		"........",
		"...k..k.",
		"...k..k.",
		"........",
		"..kkk...",
		"........",
	],
	"think_blink": [
		"........",
		"........",
		"..kk.kk.",
		"........",
		"..kkk...",
		"........",
	],
	"love": [ # easter egg: heart eyes
		"........",
		"k.k..k.k",
		"kkk..kkk",
		".k....k.",
		"..kkkk..",
		"........",
	],
	"dizzy": [ # easter egg: just the mouth; the spinning swirl eyes are drawn separately
		"........",
		"........",
		"........",
		"........",
		"...kk...",
		"........",
	],
}

## 3x5 digits for showing answers on the screen.
const DIGITS := {
	"0": ["kkk", "k.k", "k.k", "k.k", "kkk"],
	"1": [".k.", "kk.", ".k.", ".k.", "kkk"],
	"2": ["kkk", "..k", "kkk", "k..", "kkk"],
	"3": ["kkk", "..k", ".kk", "..k", "kkk"],
	"4": ["k.k", "k.k", "kkk", "..k", "..k"],
	"5": ["kkk", "k..", "kkk", "..k", "kkk"],
	"6": ["kkk", "k..", "kkk", "k.k", "kkk"],
	"7": ["kkk", "..k", "..k", ".k.", ".k."],
	"8": ["kkk", "k.k", "kkk", "k.k", "kkk"],
	"9": ["kkk", "k.k", "kkk", "..k", "kkk"],
}

## Arms are 2 pixels wide (left arm shown; the right arm is mirrored).
const ARM_REST: Array[String] = ["km", "km", "kk"]
const ARM_UP: Array[String] = ["kk", "km", "km", "km", "km"]
const ARM_REST_Y := 9
const ARM_UP_Y := 2

const DIZZY_TAPS := 5 # taps within DIZZY_WINDOW seconds
const DIZZY_WINDOW := 2.0
const DIZZY_COOLDOWN := 1.0 # seconds taps are ignored once he's dizzy
## Swirl eye, drawn at half-pixel detail (5x5 half-pixels = 2.5 screen pixels)
## so a real spiral fits. It turns a quarter every SWIRL_STEP seconds.
const SWIRL := ["kkkkk", "....k", "kkk.k", "k...k", "kkkkk"]
const SWIRL_STEP := 0.09
const HEART := ["kk.kk", "kkkkk", ".kkk.", "..k.."]
const HEART_COLORS: Array[Color] = [Color("ff6b9a"), Color("ff9eb5"), Color("ff8c42")]
const SPARKLE_COLORS: Array[Color] = [Color("ffd23f"), Color("ffffff"), Color("ff9eb5"), Color("9be7c4")]

var screen_color: Color = SCREEN_COLORS["idle"]
var hop := 0.0 # grid pixels off the ground
var tilt := 0.0 # radians
var face := "happy"
var left_arm_up := false
var right_arm_up := false
var squash := Vector2.ONE # squash & stretch, pivoting at his feet

var _mood := "idle"
var _mood_left := -1.0 # seconds until back to idle; negative = stay
var _rainbow := false
var _waving := false
var _wave_t := 0.0
var _bob := 0
var _bob_t := 0.0
var _blink_t := 2.5
var _blink_left := 0.0
var _number_cols: Array = [] # columns of 5 bools
var _marquee := 0
var _marquee_t := 0.0
var _sparkles: Array[Dictionary] = []
var _time := 0.0
var _hop_tween: Tween
var _tilt_tween: Tween
var _color_tween: Tween
var _squash_tween: Tween
var _poke_times: Array[float] = []
var _poke_locked_until := -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP # tappable (easter egg)
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(W, H) * 7.0


# --- Moods -------------------------------------------------------------------

func idle() -> void:
	_set_mood("idle", "happy", -1.0)


func cheer(duration := 1.2) -> void:
	_set_mood("happy", "joy", duration)
	left_arm_up = true
	right_arm_up = true
	_hop(3.0)


func celebrate(duration := 1.8) -> void:
	_set_mood("celebrate", "joy", duration)
	_rainbow = true
	left_arm_up = true
	right_arm_up = true
	_hop(5.0, 2)
	_burst(12)


func think(duration := 1.6) -> void:
	_set_mood("think", "think", duration)
	_tilt_to(-0.14)


## Shows a number on his screen (scrolls if it's too wide). Stays until another mood.
func show_number(n: int) -> void:
	_set_mood("help", "", -1.0)
	_set_number(str(n))


func wave(duration := 2.0) -> void:
	_set_mood("idle", "happy", duration)
	_waving = true
	_wave_t = 0.0


func _set_mood(mood: String, new_face: String, duration: float) -> void:
	_mood = mood
	face = new_face
	_mood_left = duration
	_rainbow = false
	_waving = false
	left_arm_up = false
	right_arm_up = false
	_number_cols.clear()
	if _squash_tween:
		_squash_tween.kill()
	squash = Vector2.ONE
	if SCREEN_COLORS.has(mood):
		if _color_tween:
			_color_tween.kill()
		_color_tween = create_tween()
		_color_tween.tween_property(self, "screen_color", SCREEN_COLORS[mood], 0.25)
	_tilt_to(0.0)


func _hop(height: float, times := 1) -> void:
	if _hop_tween:
		_hop_tween.kill()
	_hop_tween = create_tween()
	for i in times:
		_hop_tween.tween_property(self, "hop", height, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_hop_tween.tween_property(self, "hop", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _tilt_to(angle: float) -> void:
	if _tilt_tween:
		_tilt_tween.kill()
	_tilt_tween = create_tween()
	_tilt_tween.tween_property(self, "tilt", angle, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _burst(count: int) -> void:
	for i in count:
		var pos: Vector2
		match randi() % 3:
			0:
				pos = Vector2(randi_range(-5, -1), randi_range(-3, 14))
			1:
				pos = Vector2(randi_range(W, W + 4), randi_range(-3, 14))
			_:
				pos = Vector2(randi_range(-3, W + 2), randi_range(-5, -1))
		var life := randf_range(0.5, 1.1)
		_sparkles.append({"pos": pos, "life": life, "max": life,
			"color": SPARKLE_COLORS[randi() % SPARKLE_COLORS.size()]})


func _set_number(text: String) -> void:
	_number_cols.clear()
	for ch in text:
		var rows: Array = DIGITS[ch]
		for c in 3:
			var column: Array[bool] = []
			for r in 5:
				column.append(rows[r][c] == "k")
			_number_cols.append(column)
		_number_cols.append([false, false, false, false, false])
	_number_cols.pop_back()
	if _number_cols.size() <= SCREEN_W:
		@warning_ignore("integer_division")
		var pad := (SCREEN_W - _number_cols.size()) / 2
		for i in pad:
			_number_cols.push_front([false, false, false, false, false])
	else:
		for i in 3: # gap before the number scrolls around again
			_number_cols.append([false, false, false, false, false])
	_marquee = 0
	_marquee_t = 0.0


# --- Easter egg ----------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	# Touches arrive as emulated mouse clicks, so this covers fingers too.
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		poke()


## Tap: a giggle. DIZZY_TAPS taps in a row (quickly): a dizzy spin.
func poke() -> void:
	if _time < _poke_locked_until: # still spinning from the last dizzy spell
		return
	_poke_times.append(_time)
	_poke_times = _poke_times.filter(func(t: float) -> bool: return _time - t <= DIZZY_WINDOW)
	if _poke_times.size() >= DIZZY_TAPS:
		_poke_times.clear()
		_dizzy()
		poked.emit(true)
	else:
		_giggle()
		poked.emit(false)


func _giggle() -> void:
	if _mood == "help": # he's showing an answer: keep it on screen, just hop
		_hop(2.0)
		return
	_set_mood("love", "love", 1.3)
	_boing()
	_hop(3.0)
	for i in 3:
		var life := randf_range(0.8, 1.2)
		_sparkles.append({"pos": Vector2(randi_range(2, W - 3), randi_range(-2, 2)),
			"vel": Vector2(randf_range(-2.0, 2.0), randf_range(-9.0, -6.0)),
			"life": life, "max": life, "heart": true,
			"color": HEART_COLORS[randi() % HEART_COLORS.size()]})
	_sfx("poke")


func _dizzy() -> void:
	if _mood == "help":
		_hop(2.0)
		return
	_set_mood("dizzy", "dizzy", 2.2)
	_poke_locked_until = _time + DIZZY_COOLDOWN
	_rainbow = true
	_burst(8)
	if _tilt_tween:
		_tilt_tween.kill()
	_tilt_tween = create_tween()
	# two full spins, then a woozy wobble back to upright
	_tilt_tween.tween_property(self, "tilt", TAU * 2.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_tilt_tween.tween_callback(func() -> void: tilt = 0.0)
	for angle in [0.25, -0.2, 0.12, -0.06, 0.0]:
		_tilt_tween.tween_property(self, "tilt", angle, 0.18).set_trans(Tween.TRANS_SINE)
	_sfx("dizzy")


## Plays a sound through the Audio autoload if it's there (keeps Pip usable anywhere).
func _sfx(sound_name: String) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio:
		audio.play(sound_name)


func _boing() -> void:
	if _squash_tween:
		_squash_tween.kill()
	_squash_tween = create_tween()
	_squash_tween.tween_property(self, "squash", Vector2(1.25, 0.75), 0.08)
	_squash_tween.tween_property(self, "squash", Vector2(0.85, 1.2), 0.1)
	_squash_tween.tween_property(self, "squash", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# --- Update + draw -----------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	if _mood_left > 0.0:
		_mood_left -= delta
		if _mood_left <= 0.0:
			idle()
	_bob_t += delta
	if _bob_t >= 0.5:
		_bob_t = 0.0
		_bob = 1 - _bob
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_left = 0.14
		_blink_t = randf_range(2.0, 4.5)
	_blink_left = maxf(_blink_left - delta, 0.0)
	if _rainbow:
		screen_color = Color.from_hsv(fmod(_time * 1.2, 1.0), 0.42, 1.0)
	if _waving:
		_wave_t += delta
		right_arm_up = int(_wave_t / 0.22) % 2 == 0
	if _number_cols.size() > SCREEN_W:
		_marquee_t += delta
		if _marquee_t >= 0.14:
			_marquee_t = 0.0
			_marquee = (_marquee + 1) % _number_cols.size()
	for s in _sparkles:
		s["life"] -= delta
		if s.has("vel"):
			s["pos"] += s["vel"] * delta
	_sparkles = _sparkles.filter(func(s: Dictionary) -> bool: return s["life"] > 0.0)
	queue_redraw()


func _draw() -> void:
	var px := floorf(minf(size.x / W, size.y / H))
	if px < 1.0:
		return
	# Pivot at his feet so tilting looks like leaning.
	var feet := Vector2(roundf(size.x / 2.0), size.y - roundf(hop) * px)
	draw_set_transform(feet, tilt, squash)
	var o := Vector2(-W * px / 2.0, -H * px)
	var lift := float(_bob) if hop < 0.5 else 0.0 # gentle idle bob (feet stay put)

	for y in H:
		var row := BODY[y]
		var dy := 0.0 if y == H - 1 else -lift
		for x in W:
			var c := row[x]
			if COLORS.has(c):
				_pix(o, px, x, y + dy, COLORS[c])

	var sx := float(SCREEN_POS.x)
	var sy := SCREEN_POS.y - lift
	draw_rect(Rect2(o + Vector2(sx, sy) * px, Vector2(SCREEN_W, SCREEN_H) * px), screen_color)
	if _number_cols.is_empty():
		_pix(o, px, sx, sy, screen_color.lightened(0.55)) # little screen glare
	else:
		for i in SCREEN_W:
			var idx := (_marquee + i) % _number_cols.size() if _number_cols.size() > SCREEN_W else i
			if idx >= _number_cols.size():
				continue
			var column: Array = _number_cols[idx]
			for r in 5:
				if column[r]:
					_pix(o, px, sx + i, sy + r + 0.5, DIGIT_COLOR)
	if _number_cols.is_empty():
		var key := face + "_blink" if _blink_left > 0.0 and FACES.has(face + "_blink") else face
		if FACES.has(key):
			var rows: Array = FACES[key]
			for fy in SCREEN_H:
				for fx in SCREEN_W:
					if rows[fy][fx] == "k":
						_pix(o, px, sx + fx, sy + fy, INK)
		if face == "dizzy":
			var turn := int(_time / SWIRL_STEP) % 4
			_draw_swirl(o, px, sx + 0.5, sy + 0.5, turn, false)
			_draw_swirl(o, px, sx + 5.0, sy + 0.5, (4 - turn) % 4, true) # mirrored, spins the other way

	_draw_arm(o, px, left_arm_up, false, lift)
	_draw_arm(o, px, right_arm_up, true, lift)

	for s in _sparkles:
		var p: Vector2 = s["pos"].round()
		var col: Color = s["color"]
		if s.get("heart", false):
			for hy in HEART.size():
				for hx in HEART[hy].length():
					if HEART[hy][hx] == "k":
						_pix(o, px, p.x + hx - 2, p.y + hy - 2, col)
			continue
		_pix(o, px, p.x, p.y, col)
		if s["life"] / s["max"] > 0.5:
			for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				_pix(o, px, p.x + d.x, p.y + d.y, col)


## One spiral eye at (x, y) in screen-pixel units, rotated `turns` quarter turns.
func _draw_swirl(o: Vector2, px: float, x: float, y: float, turns: int, mirror: bool) -> void:
	var n := SWIRL.size()
	for r in n:
		for c in n:
			# rotate (r, c) back by `turns` quarter turns to find the source cell
			var sr := r
			var sc := c
			for t in turns:
				var tmp := sr
				sr = n - 1 - sc
				sc = tmp
			if mirror:
				sc = n - 1 - sc
			if SWIRL[sr][sc] == "k":
				draw_rect(Rect2(o + Vector2(x + c * 0.5, y + r * 0.5) * px, Vector2(px, px) * 0.5), INK)


func _draw_arm(o: Vector2, px: float, up: bool, right: bool, lift: float) -> void:
	var rows := ARM_UP if up else ARM_REST
	var y0 := (ARM_UP_Y if up else ARM_REST_Y) - lift
	var x0 := W - 2 if right else 0
	for i in rows.size():
		var row: String = rows[i].reverse() if right else rows[i]
		for j in 2:
			if COLORS.has(row[j]):
				_pix(o, px, x0 + j, y0 + i, COLORS[row[j]])


func _pix(o: Vector2, px: float, x: float, y: float, color: Color) -> void:
	draw_rect(Rect2(o + Vector2(x, y) * px, Vector2(px, px)), color)
