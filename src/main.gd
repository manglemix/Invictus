extends Node


func fade_change_scene(new_scene: Node, duration:=0.3) -> void:
	var screen_fade: ScreenFade = preload("res://src/transitions/screen_fade/screen_fade.tscn").instantiate()
	screen_fade.fade_duration = duration
	get_viewport().add_child(screen_fade)
	await screen_fade.faded_in
	get_tree().current_scene.queue_free()
	get_viewport().add_child(new_scene)
	get_tree().current_scene = new_scene
	if !new_scene.is_inside_tree():
		await new_scene.tree_entered
	get_viewport().move_child(new_scene, 0)
	screen_fade.fade_out()
