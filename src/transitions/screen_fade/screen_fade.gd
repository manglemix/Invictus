class_name ScreenFade
extends Panel


signal faded_in

var fade_duration := 0.3


func _ready() -> void:
	modulate.a = 0
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1, fade_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	faded_in.emit()


func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0, fade_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.finished.connect(queue_free)
