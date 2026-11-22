extends Control
## End-of-game screen. Always leads with something positive.


func _ready() -> void:
	%PlayAgainButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game.tscn"))
	%MenuButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn"))
	_show(GameSettings.last_result)
	%PlayAgainButton.grab_focus()
	# Pip always celebrates the finish; a new record gets the big rainbow party.
	if GameSettings.last_result.get("is_best", false):
		%Pip.celebrate(3.0)
		%Confetti.rain(2.5)
		Audio.play("record")
	else:
		%Pip.cheer(2.0)
		%Confetti.pop.call_deferred(%Pip.get_global_rect().get_center(), 40, 800.0)
		Audio.play("finish")


func _show(r: Dictionary) -> void:
	var correct := int(r.get("correct", 0))
	var prev: float = r.get("previous_best", -1.0)
	var is_best: bool = r.get("is_best", false)
	%RecordLabel.text = ""
	match int(r.get("mode", GameSettings.Mode.PRACTICE)):
		GameSettings.Mode.PRACTICE:
			if correct > 0:
				%HeadlineLabel.text = "You got %d right!" % correct
				%DetailLabel.text = "Best streak: %d   ·   Cards tried: %d" % [r.get("best_streak", 0), r.get("answered", 0)]
			else:
				%HeadlineLabel.text = "Thanks for practicing!"
				%DetailLabel.text = "Every try makes you stronger."
		GameSettings.Mode.STOPWATCH:
			var time: float = r.get("elapsed", 0.0)
			%HeadlineLabel.text = "Finished in %s!" % ModeBase.format_time(time)
			%DetailLabel.text = "%d cards done" % correct
			if prev < 0.0:
				%RecordLabel.text = "That's your first time. Next time, try to beat it!"
			elif is_best:
				%RecordLabel.text = "New best! %.1f seconds faster than before!" % (prev - time)
			elif time - prev < 5.0:
				%RecordLabel.text = "So close! Your best is %s." % ModeBase.format_time(prev)
			else:
				%RecordLabel.text = "Your best is %s. Keep practicing and you'll get there!" % ModeBase.format_time(prev)
		GameSettings.Mode.COUNTDOWN:
			var best := int(prev)
			%HeadlineLabel.text = "You got %d right!" % correct
			%DetailLabel.text = "in %d seconds" % int(r.get("duration", 0))
			if best < 0:
				%RecordLabel.text = "That's your first score. Can you beat it next time?"
			elif is_best:
				%RecordLabel.text = "New best! That's %d more than before!" % (correct - best)
			elif correct == best:
				%RecordLabel.text = "You tied your best!"
			else:
				%RecordLabel.text = "Your best is %d. You're getting there!" % best
