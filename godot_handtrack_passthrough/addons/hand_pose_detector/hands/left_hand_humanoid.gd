extends Node3D

func _ready():
	$"../WristUIWrapper".Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.182))
	
