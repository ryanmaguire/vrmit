class_name PointCharge extends RefCounted

var pos : Vector3
var q : float
var area : Area3D
var mesh : MeshInstance3D

func _init(pos : Vector3, q : float, area : Area3D):
	self.pos = pos
	self.q = q
	self.area = area
	mesh = area.find_child("MeshInstance3D")
