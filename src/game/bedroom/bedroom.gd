class_name Bedroom
extends VBoxContainer


var bedroom_owner: PlayerState
var modifiable := false


func _ready() -> void:
	if modifiable:
		$TextureRect/SubViewport/ReflectionProbe.update_mode = ReflectionProbe.UPDATE_ALWAYS
