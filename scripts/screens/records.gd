extends Control
## Best time / best score for each settings combo, with a chart of recent tries.

const KINDS := {
	"stopwatch": {"title": "Beat Your Time", "mode": "Beat Your Time"},
	"countdown": {"title": "Countdown", "mode": "Countdown"},
}
const COLOR_MUTED := Color(0.2, 0.22, 0.3, 0.6)
const COLOR_BLUE := Color(0.34, 0.52, 0.96)
const COLOR_GOOD := Color(0.18, 0.6, 0.35)

var _tab_buttons := {}


func _ready() -> void:
	%BackButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn"))
	var group := ButtonGroup.new()
	for kind in KINDS:
		var b := Button.new()
		b.text = KINDS[kind]["title"]
		b.toggle_mode = true
		b.button_group = group
		b.theme_type_variation = &"Chip"
		b.custom_minimum_size = Vector2(260, 72)
		b.pressed.connect(_show.bind(kind))
		%Tabs.add_child(b)
		_tab_buttons[kind] = b
	# Open the tab you played most recently.
	var first := "stopwatch"
	var sw := SaveData.get_records("stopwatch")
	var cd := SaveData.get_records("countdown")
	if not cd.is_empty() and (sw.is_empty() or cd[0]["last_played"] > sw[0]["last_played"]):
		first = "countdown"
	_tab_buttons[first].button_pressed = true
	_show(first)
	resized.connect(func() -> void:
		for box in get_tree().get_nodes_in_group("charts"):
			box.visible = size.x > size.y)


func _show(kind: String) -> void:
	for child in %List.get_children():
		child.queue_free()
	var records := SaveData.get_records(kind)
	%Empty.visible = records.is_empty()
	%Scroll.visible = not records.is_empty()
	if records.is_empty():
		%EmptyLabel.text = "No records yet!\nPlay %s to set your first one." % KINDS[kind]["mode"]
		%EmptyPip.wave()
		return
	for record in records:
		%List.add_child(_make_row(kind, record))


func _make_row(kind: String, record: Dictionary) -> Control:
	var info := SaveData.describe_key(record["key"])
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	panel.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(left)
	left.add_child(_label(info["ops"], 52, COLOR_BLUE))
	var tries: int = record["history"].size()
	left.add_child(_label("Level %d %s" % [info["level"], info["level_name"]], 24, COLOR_MUTED))
	left.add_child(_label("%s  ·  %d %s" % [info["length"], tries, "try" if tries == 1 else "tries"],
		24, COLOR_MUTED))

	var chart_box := VBoxContainer.new()
	chart_box.add_to_group("charts")
	chart_box.visible = size.x > size.y # charts only fit in landscape
	chart_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(chart_box)
	var chart := RecordChart.new()
	chart.custom_minimum_size = Vector2(220, 70)
	chart.setup(record["history"], kind == "stopwatch")
	chart_box.add_child(chart)
	chart_box.add_child(_label("Recent tries", 20, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.custom_minimum_size = Vector2(170, 0)
	row.add_child(right)
	right.add_child(_label("Best", 24, COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	var best_text := ModeBase.format_time(record["best"]) if kind == "stopwatch" \
		else "%d right" % int(record["best"])
	right.add_child(_label(best_text, 44, COLOR_GOOD, HORIZONTAL_ALIGNMENT_RIGHT))
	return panel


func _label(text: String, font_size: int, color: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l
