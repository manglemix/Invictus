class_name Bedroom
extends VBoxContainer


var bedroom_owner: PlayerState
var modifiable := true:
	set(x):
		modifiable = x
		for child in $SubViewportContainer/SubViewport/Furniture.get_children():
			if child is Draggable:
				child.enabled = modifiable


func _process(_delta: float) -> void:
	if GameState.timer <= 0.0:
		set_process(false)
		await get_tree().create_timer(GameState.VOTE_REVEAL_TIME).timeout
		Main.fade_change_scene(preload("res://src/game/free_roam_map/free_roam_map.tscn").instantiate())
