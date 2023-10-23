class_name TopVotedEntry
extends HBoxContainer


var state: PlayerState


func _ready() -> void:
	$Label.text = state.name
	for voter in state.votes:
		var label := Label.new()
		label.text = voter
		$ScrollContainer/HBoxContainer.add_child(label)
