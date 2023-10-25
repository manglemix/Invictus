class_name PlayerState
extends RefCounted


signal name_changed

var name: StringName:
	set(value):
		name = value
		name_changed.emit()
var multiplayer_id: int
var is_infected: bool
var is_designated_survivor: bool
var is_fixer: bool

var bed_rotation: float
var bed_origin: Vector2

var votes: Array[StringName] = []


static func from_dict(dict: Dictionary) -> PlayerState:
	var state := PlayerState.new()
	state.name = dict["name"]
	state.multiplayer_id = dict["multiplayer_id"]
	state.is_infected = dict["is_infected"]
	state.is_designated_survivor = dict["is_designated_survivor"]
	return state


func to_dict() -> Dictionary:
	return {
		"name": name,
		"multiplayer_id": multiplayer_id,
		"is_infected": is_infected,
		"is_designated_survivor": is_designated_survivor
	}
