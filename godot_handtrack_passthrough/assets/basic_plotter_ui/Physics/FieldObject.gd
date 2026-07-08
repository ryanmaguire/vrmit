class_name FieldObject extends RefCounted

enum ObjectType 
{
	POINT_CHARGE,
	BAR_MAGNET
}

var object_type: ObjectType
var pos : Vector3
var area : Area3D
var mesh : MeshInstance3D

func _init(pos : Vector3, area : Area3D, mesh : MeshInstance3D):
	self.pos = pos
	self.area = area
	self.mesh = mesh
