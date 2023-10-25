class_name Draggable
extends RigidBody3D


var drag_origin: Vector3
var enabled := true:
	set(x):
		enabled = x
		if enabled:
			input_ray_pickable = true
		else:
			input_ray_pickable = false
			set_physics_process(false)


func _ready() -> void:
	set_physics_process(false)


func _input_event(_camera: Camera3D, event: InputEvent, position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			drag_origin = to_local(position)
			set_physics_process(true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		set_physics_process(false)


func _physics_process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var from := to_global(drag_origin)
	var plane := Plane(Vector3.UP, from.y)
	var to: Vector3 = plane.intersects_ray(camera.global_position, camera.project_ray_normal(get_viewport().get_mouse_position()))
	var force := (to - from) * 6
	apply_force(force, drag_origin)
