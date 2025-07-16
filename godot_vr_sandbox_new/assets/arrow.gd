@tool
extends Node3D

@export var update = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if update:
		setLength(1)
		setRotation(0)
		print("goon")
		update = false
	
func setLength(length: float) -> void:
	if length == 0:
		queue_free()
	var mesh = ($Rectangle.mesh as BoxMesh)
	mesh.size = Vector3(length, mesh.size.y, mesh.size.z)
	$Triangle.transform.origin.x = length / 2# + 0.2
	
func setRotation(angle: float) -> void:
	rotation.y = angle
	
