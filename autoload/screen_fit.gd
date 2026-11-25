extends Node
## Keeps UI at a comfortable size in both orientations by swapping the base
## resolution: 1280x720 for landscape, 720x1280 for portrait (phones/tablets).
##
## Also keeps each screen's content out of the phone's camera hole / notch
## (the "safe area"). Backgrounds and full-screen effects still fill the whole
## display; only the content nodes are moved inward.

const LANDSCAPE := Vector2i(1280, 720)
const PORTRAIT := Vector2i(720, 1280)
## Direct children of a screen that should keep covering the whole display.
const FULL_BLEED := ["PauseOverlay", "Confetti"]

## Distance (in UI units) the content is kept from each edge: left, top, right, bottom.
var insets := Vector4.ZERO
## Developer override, in UI units, from --safe-inset=L,T,R,B. Lets a desktop
## window preview how a cutout would push the layout.
var debug_insets := Vector4(-1, -1, -1, -1)


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--safe-inset="):
			var p := arg.get_slice("=", 1).split(",")
			if p.size() == 4:
				debug_insets = Vector4(float(p[0]), float(p[1]), float(p[2]), float(p[3]))
	get_tree().root.size_changed.connect(_fit)
	get_tree().scene_changed.connect(_apply_current)
	_fit()


func _fit() -> void:
	var window := get_tree().root
	var portrait := window.size.y > window.size.x
	window.content_scale_size = PORTRAIT if portrait else LANDSCAPE
	insets = _read_insets()
	_apply_current()


## The OS safe area converted from screen pixels into UI units.
func _read_insets() -> Vector4:
	if debug_insets.x >= 0:
		return debug_insets
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window := get_tree().root
	var win := Vector2(window.size)
	if win.x <= 0 or win.y <= 0:
		return Vector4.ZERO
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	var to_ui := window.get_visible_rect().size.x / win.x
	return Vector4(
		maxf(safe.position.x, 0.0),
		maxf(safe.position.y, 0.0),
		maxf(win.x - safe.end.x, 0.0),
		maxf(win.y - safe.end.y, 0.0)) * to_ui


func _apply_current() -> void:
	var scene := get_tree().current_scene
	if scene is Control:
		apply_to(scene)


## Moves every content child of a screen into the safe area. Safe to call
## repeatedly: the scene's own offsets are remembered and reused.
func apply_to(screen: Control) -> void:
	for child in screen.get_children():
		if child is Control and not (child.name in FULL_BLEED):
			_inset(child)


func _inset(c: Control) -> void:
	if not c.has_meta("base_offsets"):
		c.set_meta("base_offsets", Vector4(c.offset_left, c.offset_top, c.offset_right, c.offset_bottom))
	var base: Vector4 = c.get_meta("base_offsets")
	# An edge anchored to the left/top side moves right/down by that side's
	# inset; one anchored to the right/bottom moves in by the other side's.
	c.offset_left = base.x + lerpf(insets.x, -insets.z, c.anchor_left)
	c.offset_top = base.y + lerpf(insets.y, -insets.w, c.anchor_top)
	c.offset_right = base.z + lerpf(insets.x, -insets.z, c.anchor_right)
	c.offset_bottom = base.w + lerpf(insets.y, -insets.w, c.anchor_bottom)
