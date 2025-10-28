@tool
extends MeshInstance3D

@export var create = false
@export var update = false
@export var parse = false
const a_min: int = -10
const a_max: int = 10
@export_range(a_min, a_max, 0.01) var a: float = 0
@export var x_min: int
@export var x_max: int
@export var y_min: int
@export var y_max: int
@export var z_min: int
@export var z_max: int
@export var expressionX: String
@export var expressionY: String
@export var expressionZ: String
#@export var start_left: float
#@export var start_right: float
#@export var find_root = false
@export var resolution: int
@export var render_type: int # 0 for nothing, 1 for color, 2 for alpha

@export var arrow_material: Material

@export var function : Node3D

var vectors = []
var vertices = []
var indices = []
var v_max: float

var mdt : MeshDataTool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignals.connect("expressions_entered", _on_expressions_entered)
	GlobalSignals.connect("set_field_render", _on_set_field_render)
	#GlobalSignals.connect("update_slider", _on_update_slider)
	#GlobalSignals.connect("update_function_scale", _on_update_slider)
	#GlobalSignals.connect("set_rotating", _on_set_rotating)
	#GlobalSignals.connect("update_plot_scale", _on_update_plot_scale)
		
	if function:
		function.initialize()
	_on_expressions_entered("0", "0", "0")
	rotation_degrees = Vector3(0, 0, 0)
	
func _on_set_field_render(type : int):
	render_type = type
	upd()

func _on_expressions_entered(exprX: String, exprY: String, exprZ: String):
	#print("New Expression: " + expr)
	#expression_z = expr
	if (exprX == "" or exprY == "" or exprZ == ""): 
		function.set_string(expressionX, 1)
		function.set_string(expressionY, 2)
		function.set_string(expressionZ, 3)
	else:
		function.set_string(exprX, 1)
		function.set_string(exprY, 2)
		function.set_string(exprZ, 3)
	gen()
	
func calculate_field(xmin: int, xmax: int, ymin: int, ymax: int, zmin: int, zmax: int, res: int) -> void:
	vectors = []
	v_max = 0

	var X: float
	var Y: float
	var Z: float
	var V: Vector3
		
	for x in range(xmin * res, xmax * res + 1):
		vectors.append([])
		for y in range(ymin * res, ymax * res + 1):
			vectors[x - x_min].append([])
			for z in range(zmin * res, zmax * res + 1):
				X = float(x) / res
				Y = float(y) / res
				Z = float(z) / res
				V = Vector3(function.calculate_para(X, Z, Y, 1), function.calculate_para(X, Z, Y, 2), function.calculate_para(X, Z, Y, 3))
				#V = Vector3(function.calculate(X, Z, Y, 1), function.calculate(X, Z, Y, 2), function.calculate(X, Z, Y, 3))
				vectors[x - x_min][y - y_min].append(V)
				if V.length() > v_max:
					v_max = V.length()
				
func create_field(xmin: int, xmax: int, ymin: int, ymax: int, zmin: int, zmax: int, res: int) -> void:
	mesh.clear_surfaces()
	var a_mesh = ArrayMesh.new()
	
	mdt = MeshDataTool.new()

	var array = []
	array.resize(Mesh.ARRAY_MAX)
	vertices = PackedVector3Array()
	indices = PackedInt32Array()
	
	var n = 0

	var X: float
	var Y: float
	var Z: float
	var V: Vector3
	
	for x in range(xmin * res, xmax * res + 1):
		for y in range(ymin * res, ymax * res + 1):
			for z in range(zmin * res, zmax * res + 1):
				X = float(x) / res
				Y = float(y) / res
				Z = float(z) / res
				create_arrow(Vector3(X, Z, Y), vectors[x - x_min][y - y_min][z - z_min], n)
				n += 1
	
	array[Mesh.ARRAY_VERTEX] = vertices
	array[Mesh.ARRAY_INDEX] = indices
	
	a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	
	mesh = a_mesh
	mesh.surface_set_material(0, arrow_material)
	mdt.create_from_surface(mesh, 0)
	
	n = 0
	
	for x in range(xmin * res, xmax * res + 1):
		for y in range(ymin * res, ymax * res + 1):
			for z in range(zmin * res, zmax * res + 1):
				var c: Color
				if (render_type == 0):
					c = Color(1, 1, 1)
				elif (render_type == 1):
					var fraction = vectors[x - x_min][y - y_min][z - z_min].length() / v_max
					c = Color.from_hsv(1 - fraction, 1, 1)
				elif (render_type == 2):
					var fraction = vectors[x - x_min][y - y_min][z - z_min].length() / v_max
					c = Color(1, 0.2, 0.2, fraction)
				else:
					c = Color(1, 1, 1)
				for v in range(6):
					#var vid = mdt.get_face_vertex(face_i, v_i)
					mdt.set_vertex_color(n * 6 + v, c)
				n += 1
	
	mesh.surface_remove(0)
	#mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)

func update_field(xmin: int, xmax: int, ymin: int, ymax: int, zmin: int, zmax: int, res: int) -> void:
	mesh.clear_surfaces()
	var a_mesh = ArrayMesh.new()
	
	mdt = MeshDataTool.new()

	var array = []
	array.resize(Mesh.ARRAY_MAX)
	vertices = PackedVector3Array()
	indices = PackedInt32Array()
	
	var n = 0

	var X: float
	var Y: float
	var Z: float
	var V: Vector3
	
	for x in range(xmin * res, xmax * res + 1):
		for y in range(ymin * res, ymax * res + 1):
			for z in range(zmin * res, zmax * res + 1):
				X = float(x) / res
				Y = float(y) / res
				Z = float(z) / res
				create_arrow(Vector3(X, Z, Y), vectors[x - x_min][y - y_min][z - z_min], n)
				n += 1
	
	array[Mesh.ARRAY_VERTEX] = vertices
	array[Mesh.ARRAY_INDEX] = indices
	
	a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	
	mesh = a_mesh
	mesh.surface_set_material(0, arrow_material)
	mdt.create_from_surface(mesh, 0)
	
	n = 0
	
	for x in range(xmin * res, xmax * res + 1):
		for y in range(ymin * res, ymax * res + 1):
			for z in range(zmin * res, zmax * res + 1):
				var c: Color
				if (render_type == 0):
					c = Color(1, 1, 1)
				elif (render_type == 1):
					var fraction = vectors[x - x_min][y - y_min][z - z_min].length() / v_max
					c = Color.from_hsv(1 - fraction, 1, 1)
				elif (render_type == 2):
					var fraction = vectors[x - x_min][y - y_min][z - z_min].length() / v_max
					c = Color(1, 0.2, 0.2, fraction)
				else:
					c = Color(1, 1, 1)
				for v in range(6):
					#var vid = mdt.get_face_vertex(face_i, v_i)
					mdt.set_vertex_color(n * 6 + v, c)
				n += 1
	
	mesh.surface_remove(0)
	#mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)

				
func create_arrow(origin : Vector3, direction : Vector3, index : int) -> void:
	vertices.append(origin + (Vector3.ZERO if direction == Vector3.ZERO else Quaternion(Vector3.UP, direction) * Vector3.RIGHT * 0.1))
	vertices.append(origin + (Vector3.ZERO if direction == Vector3.ZERO else Quaternion(Vector3.UP, direction) * Vector3.RIGHT * -0.1))
	vertices.append(origin + direction.normalized() * atan(direction.length()) / PI / resolution * 2)
	
	vertices.append(origin + (Vector3.ZERO if direction == Vector3.ZERO else Quaternion(Vector3.UP, direction) * Vector3.FORWARD * 0.1))
	vertices.append(origin + (Vector3.ZERO if direction == Vector3.ZERO else Quaternion(Vector3.UP, direction) * Vector3.FORWARD * -0.1))
	vertices.append(origin + direction.normalized() * atan(direction.length()) / PI / resolution * 2)
	
	'''vertices.append(Vector3(0, -0.1, 0))
	vertices.append(Vector3(0, 0.1, 0))
	vertices.append(Vector3(0.8, -0.1, 0))
	vertices.append(Vector3(0.8, 0.1, 0))
	
	vertices.append(Vector3(1, 0, 0))
	vertices.append(Vector3(0.8, 0, -0.2))
	vertices.append(Vector3(0.8, 0, 0.2))
	
	vertices.append(Vector3(0, 0, -0.1))
	vertices.append(Vector3(0, 0, 0.1))
	vertices.append(Vector3(0.8, 0, -0.1))
	vertices.append(Vector3(0.8, 0, 0.1))'''
	
	indices.append(index * 6 + 0)
	indices.append(index * 6 + 1)
	indices.append(index * 6 + 2)
	
	indices.append(index * 6 + 3)
	indices.append(index * 6 + 4)
	indices.append(index * 6 + 5)

func gen():
	var start_time = Time.get_ticks_msec()
	#initialize_mesh(x_min, x_max, z_min, z_max, resolution)
	calculate_field(x_min, x_max, y_min, y_max, z_min, z_max, resolution)
	create_field(x_min, x_max, y_min, y_max, z_min, z_max, resolution)
	var end_time = Time.get_ticks_msec()
	#update_extensions()
	#print("Elapsed time: " + str(end_time - start_time) + " ms")
	#place_tangent_plane(5, -5);

func upd():
	var start_time = Time.get_ticks_msec()
	#initialize_mesh(x_min, x_max, z_min, z_max, resolution)
	calculate_field(x_min, x_max, y_min, y_max, z_min, z_max, resolution)
	update_field(x_min, x_max, y_min, y_max, z_min, z_max, resolution)
	var end_time = Time.get_ticks_msec()
	#update_extensions()
	#print("Elapsed time: " + str(end_time - start_time) + " ms")
	#place_tangent_plane(5, -5);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if create:
		gen()
		create = false
	if update:
		upd()
		update = false
	if parse:
		_on_expressions_entered("", "", "")
		parse = false
