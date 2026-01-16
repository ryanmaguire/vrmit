@tool
# In a script attached to your MeshInstance3D
extends MeshInstance3D

## Orients the plane
##
## @param direction: which direction to point, magnitude matters not
## @param color: color of arrow, default RED
func turn_plane(direction: Vector3, color: Color = Color.RED):
	rotation = Vector3.ZERO
	transform.basis = Basis(Quaternion(transform.basis.z, direction))
	
