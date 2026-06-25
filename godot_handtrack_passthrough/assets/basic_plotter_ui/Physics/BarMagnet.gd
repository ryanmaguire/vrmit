class_name BarMagnet extends FieldObject

var m : Vector3

func _init(pos : Vector3, m : Vector3, area : Area3D):
	self.object_type = ObjectType.BAR_MAGNET
	self.pos = pos
	self.m = m
	self.area = area
	mesh = area.find_child("MeshInstance3D")
