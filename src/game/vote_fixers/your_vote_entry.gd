class_name YourVoteEntry
extends HBoxContainer


var player_name: StringName


func _ready() -> void:
	$Label.text = player_name


func _on_check_box_toggled(button_pressed: bool) -> void:
	if button_pressed:
		GameState.vote_for(player_name)
	else:
		GameState.unvote_for(player_name)
