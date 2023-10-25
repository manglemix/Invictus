class_name RoundTimer
extends Label


func _process(_delta: float) -> void:
	text = "%s seconds left" % roundi(GameState.timer)
	if roundi(GameState.timer) <= 10:
		modulate = Color.RED
	else:
		modulate = Color.WHITE
