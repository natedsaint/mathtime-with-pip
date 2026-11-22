extends Node
## Developer helper. Does nothing in normal play.
## Screenshot a screen:  godot --path . -- --shot=game --mode=1 --out=/tmp/shot.png
## Optional: --ops=0,2 (Question.Op values)  --level=2  --keys=56 (types into the game)

func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	if args.has("make-icons"):
		_make_icons()
	elif args.has("export-sfx"):
		_export_sfx(str(args["export-sfx"]))
	elif args.has("shot"):
		_take_shot(args)


## Uses a throwaway save file filled with sample runs (your real records are untouched).
func _fake_records() -> void:
	SaveData.path = "user://dev_progress.cfg"
	SaveData.cfg = ConfigFile.new()
	for s in [12, 15, 14, 18, 21]:
		SaveData.record_countdown("add-sub_L1_t60", s)
	for t in [148.2, 139.5, 141.0, 131.7, 126.3, 128.9, 119.4]:
		SaveData.record_stopwatch("mul_L2_n20", t)
	for t in [52.0, 47.5, 49.1]:
		SaveData.record_stopwatch("add-sub_L1_n10", t)
	for t in [201.3]:
		SaveData.record_stopwatch("add-sub-mul-div_L3_n30", t)


## Renders the app icons from Pip's pixel grid:
##   icon.png        full-bleed square (iOS, Android, web, Windows)
##   icon_macos.png  rounded square with margin, the shape macOS expects
func _make_icons() -> void:
	_draw_icon("res://icon.png", 0, 0, 40)
	_draw_icon("res://icon_macos.png", 100, 185, 32)
	print("Icons written.")
	get_tree().quit()


func _draw_icon(path: String, inset: int, radius: int, px: int) -> void:
	const SIZE := 1024
	var bg := Color("5b86f6")
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	if inset == 0:
		img.fill(bg)
	else:
		img.fill(Color(0, 0, 0, 0))
		var inner := SIZE - inset * 2
		for y in inner:
			for x in inner:
				# distance into the rounded corner, if we're in one
				var cx := clampi(x, radius, inner - 1 - radius)
				var cy := clampi(y, radius, inner - 1 - radius)
				if Vector2(x - cx, y - cy).length() <= radius:
					img.set_pixel(inset + x, inset + y, bg)
	var grid := _icon_grid()
	var colors := Pip.COLORS.duplicate()
	colors["s"] = Pip.SCREEN_COLORS["idle"]
	var ox := (SIZE - Pip.W * px) / 2
	var oy := (SIZE - Pip.H * px) / 2
	for y in Pip.H:
		for x in Pip.W:
			var c: String = grid[y][x]
			if colors.has(c):
				img.fill_rect(Rect2i(ox + x * px, oy + y * px, px, px), colors[c])
	img.save_png(ProjectSettings.globalize_path(path))


## Pip with arms up and a big grin, as rows of characters.
func _icon_grid() -> Array:
	var grid := []
	for row in Pip.BODY:
		var chars := []
		for ch in row:
			chars.append("s" if ch == "S" else ch)
		grid.append(chars)
	var face: Array = Pip.FACES["joy"]
	for fy in Pip.SCREEN_H:
		for fx in Pip.SCREEN_W:
			if face[fy][fx] == "k":
				grid[Pip.SCREEN_POS.y + fy][Pip.SCREEN_POS.x + fx] = "k"
	for i in Pip.ARM_UP.size():
		var row: String = Pip.ARM_UP[i]
		var mirrored := row.reverse()
		for j in 2:
			grid[Pip.ARM_UP_Y + i][j] = row[j]
			grid[Pip.ARM_UP_Y + i][Pip.W - 2 + j] = mirrored[j]
	return grid


## Saves every synthesized sound as a .wav so you can listen outside the game.
func _export_sfx(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for sound_name in Audio.SOUNDS:
		var stream: AudioStream = Audio._streams[sound_name]
		if stream is AudioStreamWAV:
			(stream as AudioStreamWAV).save_to_wav(dir.path_join(sound_name + ".wav"))
	print("Exported sounds to ", dir)
	get_tree().quit()


func _take_shot(args: Dictionary) -> void:
	if args.has("mode"):
		GameSettings.mode = int(args["mode"]) as GameSettings.Mode
	if args.has("level"):
		GameSettings.level = int(args["level"])
	if args.has("ops"):
		GameSettings.ops.clear()
		for op in str(args["ops"]).split(","):
			GameSettings.ops.append(int(op))
	if args.has("fake-records"):
		_fake_records()
	if args["shot"] == "results":
		GameSettings.last_result = {"mode": GameSettings.mode, "correct": 14, "answered": 16,
			"best_streak": 6, "elapsed": 102.4, "duration": 60.0, "previous_best": 108.0, "is_best": true}
	await get_tree().process_frame
	# --size=WxH renders offscreen at an exact pixel size (e.g. App Store screenshots
	# bigger than this screen). Otherwise the screen is shot from the real window.
	var vp: Viewport = get_viewport()
	var scene: Node
	if args.has("size"):
		var wh := str(args["size"]).split("x")
		var px := Vector2i(int(wh[0]), int(wh[1]))
		var sub := SubViewport.new()
		sub.size = px
		sub.size_2d_override = _logical_size(px)
		sub.size_2d_override_stretch = true
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_tree().root.add_child(sub)
		get_tree().current_scene.queue_free()
		scene = load("res://scenes/%s.tscn" % args["shot"]).instantiate()
		sub.add_child(scene)
		vp = sub
		for i in 10:
			await get_tree().process_frame
	else:
		get_tree().change_scene_to_file("res://scenes/%s.tscn" % args["shot"])
		for i in 10:
			await get_tree().process_frame
		scene = get_tree().current_scene
	# An offscreen/background window counts as "app lost focus", which auto-pauses
	# timed games. Undo that unless the shot asks for the pause menu.
	if "paused" in scene and scene.paused and not args.has("pause"):
		scene._set_paused(false)
	if args.has("keys"):
		for ch in str(args["keys"]):
			var ev := InputEventKey.new()
			ev.pressed = true
			ev.unicode = ch.unicode_at(0)
			ev.keycode = KEY_ENTER if ch == "\n" or ch == "=" else KEY_NONE
			Input.parse_input_event(ev)
			await get_tree().process_frame
	if args.has("pause"):
		scene._set_paused(true)
	if args.has("miss"): # answer wrong N times (3 = Pip shows the answer)
		for n in int(args["miss"]):
			for ch in str(scene.question.answer + 1):
				scene._on_digit(int(ch))
			scene._on_submit()
			await get_tree().process_frame
	if args.has("answer"): # answer N cards correctly (e.g. 5 shows the streak party)
		for n in int(args["answer"]):
			var game: Node = scene
			for f in 120:
				if game.state == game.State.INPUT:
					break
				await get_tree().process_frame
			for ch in str(game.question.answer):
				game._on_digit(int(ch))
			game._on_submit()
		for i in int(args.get("wait", "8")):
			await get_tree().process_frame
	else:
		for i in 30:
			await get_tree().process_frame
	var img := vp.get_texture().get_image()
	img.save_png(args.get("out", "user://shot.png"))
	get_tree().quit()


## The UI size ScreenFit would use for a window of this many pixels.
func _logical_size(px: Vector2i) -> Vector2i:
	var w := float(px.x)
	var h := float(px.y)
	if h > w: # portrait, base 720x1280
		return Vector2i(720, roundi(720.0 * h / w)) if h / w > 16.0 / 9.0 else Vector2i(roundi(1280.0 * w / h), 1280)
	return Vector2i(1280, roundi(1280.0 * h / w)) if w / h < 16.0 / 9.0 else Vector2i(roundi(720.0 * w / h), 720)
