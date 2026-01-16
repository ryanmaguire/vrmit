extends Node3D

func _enter_tree() -> void:
	GlobalSignals.connect("set_axis_visibility", _on_set_visibility)

func _exit_tree() -> void:
	if GlobalSignals.is_connected("set_axis_visibility", _on_set_visibility):
		GlobalSignals.disconnect("set_axis_visibility", _on_set_visibility)
		
## Toggles visibility of the cartesian basis
##
## @param is_visible: whether it is visible or not
func _on_set_visibility(is_visible: bool) -> void:
	visible = is_visible
