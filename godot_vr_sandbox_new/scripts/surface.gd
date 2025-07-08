@tool
extends MeshInstance3D

@export var update = false
@export var x_min: int
@export var x_max: int
@export var z_min: int
@export var z_max: int
@export var resolution: int

var function

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	function = $Function
	function.initialize()
	#gen_mesh(x_min, x_max, z_min, z_max, resolution)
	
func gen_mesh(xmin: int, xmax: int, zmin: int, zmax: int, res: int):
	var a_mesh = ArrayMesh.new()
	var vertices := PackedVector3Array([])
	var indices := PackedInt32Array([])
	var heights := PackedFloat32Array([])
	var h_min: float = 1.79769e308
	var h_max: float = -1.79769e308
	
	for x in range(xmin * res, xmax * res + 1):
		for z in range(zmin * res, zmax * res + 1):
			var X: float = float(x) / res
			var Z: float = float(z) / res
			var H: float = function.calculate(X, Z)
			vertices.append(Vector3(X, H, Z))
			if (x < xmax * res and z < zmax * res):
				heights.append(H);
			if (H < h_min):
				h_min = H
			if (H > h_max):
				h_max = H
	
	var offset = (zmax - zmin) * res + 1
	for x in range(0, (xmax - xmin) * res):
		for z in range(0, (zmax - zmin) * res):
			
			# front
			indices.append(x * offset + z)
			indices.append((x + 1) * offset + z)
			indices.append(x * offset + z + 1)
			
			indices.append((x + 1) * offset + z)
			indices.append((x + 1) * offset + z + 1)
			indices.append(x * offset + z + 1)
			
			# bottom
			indices.append(x * offset + z)
			indices.append(x * offset + z + 1)
			indices.append((x + 1) * offset + z)
			
			indices.append((x + 1) * offset + z)
			indices.append(x * offset + z + 1)
			indices.append((x + 1) * offset + z + 1)

	print("Total vertices: " + str(vertices.size()))
	#print((x_max - x_min) * resolution * offset + (z_max - z_min) * resolution)
	
	var uvs = PackedVector2Array([
		Vector2(0,0),
		Vector2(1,0),
		Vector2(1,1),
	])
	
	var array = []
	array.resize(Mesh.ARRAY_MAX)
	array[Mesh.ARRAY_VERTEX] = vertices
	array[Mesh.ARRAY_INDEX] = indices
	a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	
	mesh = a_mesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	for face_i in range(mdt.get_face_count()):
		# Pick or compute a Color for this triangle
		var fraction = (heights[face_i / 4] - h_min) / (h_max - h_min);
		var c = Color(fraction, fraction, fraction)
		for v_i in range(3):
			var vid = mdt.get_face_vertex(face_i, v_i)
			mdt.set_vertex_color(vid, c)

	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	#mesh.get_surface_override_material().albedo_color = Color(1, 0, 0, 1)

	
	'''var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(vertices.size()):
		surface_tool.set_uv(uvs[i])
		surface_tool.add_vertex(vertices[i])
	for i in indices:
		surface_tool.add_index(i)
	surface_tool.generate_normals()
	a_mesh = surface_tool.commit()
	mesh = a_mesh'''
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if update:
		gen_mesh(x_min, x_max, z_min, z_max, resolution)
		update = false
