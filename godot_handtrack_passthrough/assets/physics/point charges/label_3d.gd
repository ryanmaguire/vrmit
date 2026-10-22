extends Label3D

@export var vertical_offset := 0.045

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var charge := get_parent() as Node3D

	global_position = charge.global_position + Vector3.UP * vertical_offset
	look_at(camera.global_position, Vector3.UP, true)
