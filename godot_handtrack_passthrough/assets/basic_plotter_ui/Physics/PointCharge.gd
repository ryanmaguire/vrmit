class_name PointCharge extends RefCounted

var pos : Vector3
var q : float
var node : Node3D
var mesh : MeshInstance3D

func _init(pos : Vector3, q : float, node : Node3D):
	self.pos = pos
	self.q = q
	self.node = node
	mesh = node.find_child("MeshInstance3D")
