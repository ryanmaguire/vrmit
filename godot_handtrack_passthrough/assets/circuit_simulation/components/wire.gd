class_name Wire extends CircuitComponent

## wire component
@export var mesh_instance : MeshInstance3D
@export var snap_a : SnapPoint
@export var snap_b : SnapPoint


## Position the two terminals and stretch the mesh to span them.
## [param a] and [param b] are in this wire's local space.
func set_endpoints(a : Vector3, b : Vector3) -> void:
	if snap_a:
		snap_a.position = a
	if snap_b:
		snap_b.position = b
	_orient_mesh(a, b)


## Orient/scale the cylinder to run from a to b.
func _orient_mesh(a : Vector3, b : Vector3) -> void:
	if mesh_instance == null:
		return
	var dir := b - a
	var length := dir.length()
	if length < 0.0001:
		mesh_instance.visible = false
		return
	mesh_instance.visible = true
	var mid := (a + b) * 0.5
	var n := dir / length
	var basis := Basis(Quaternion(Vector3.UP, n))
	mesh_instance.transform = Transform3D(basis, mid)
	mesh_instance.scale = Vector3(1.0, length * 0.5, 1.0)
