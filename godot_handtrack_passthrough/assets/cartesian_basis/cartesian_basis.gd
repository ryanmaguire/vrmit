extends Node3D

func _read():
	GlobalSignals.set_origin.connect(_on_set_origin)
	
func _on_set_origin():
	self.visible = !self.visible
