@tool
extends MeshInstance3D

@export var fill_material: StandardMaterial3D
@export var outline_material: StandardMaterial3D
@export var outline_offset: float = 0.01

var hasGenerated = false

var surface
var x_min
var x_max
var z_min
var z_max
var res

func _ready():
	hasGenerated = false
	surface = get_parent()
	
## Generates each layer of the level curves
func generate_level_mesh_layers():
	print("generate")
	"""
	Generates polygon layers for each integer y-level between the min and max y of the surface.
	"""
	for c in get_children():
		c.queue_free()

	x_min = surface.x_min
	x_max = surface.x_max
	z_min = surface.z_min
	z_max = surface.z_max
	res = surface.resolution

	# --- Find min and max y across the surface ---
	var min_y = INF
	var max_y = -INF
	for row in surface.heights:
		for col in row:
			for idx in col:
				var y_val = idx
				if y_val < min_y:
					min_y = y_val
				if y_val > max_y:
					max_y = y_val

	min_y = floor(min_y)
	max_y = ceil(max_y)

	# --- Generate polygon layers for each integer y ---
	for y_level in range(int(min_y), int(max_y) + 1):
		var loops = extract_level_loops(y_level)
		if loops.is_empty():
			print("failed to generate at " + str(y_level))
			continue
		var layer := create_polygon_layer_from_loops(loops, y_level)
		add_child(layer)
	
	hasGenerated = true;

## Finds the perimeter for one layer
##
## @param y_threshold: the y-cutoff for marching squares to find the perimeter
## @return: array containing the points of
func extract_level_loops(y_threshold: float) -> Array:
	var loops: Array = []
	if not surface.has_method("coordsToIndexReal") or surface.heights.is_empty():
		push_error("Surface does not provide heights or coordsToIndexReal")
		return loops

	var width = int((x_max - x_min) * res)
	var depth = int((z_max - z_min) * res)

	# --- Sample scalar field ---
	var values: Array = []
	values.resize((width + 1) * (depth + 1))
	for gz in range(depth + 1):
		for gx in range(width + 1):
			var x = x_min + gx / float(res)
			var z = z_min + gz / float(res)
			var idx = surface.coordsToIndexReal(int(x * res), int(z * res), true)
			if idx < 0 or idx >= surface.heights[0][0].size():
				continue
			var y_val = surface.heights[0][0][idx]
			values[gz * (width + 1) + gx] = y_val > y_threshold

	# --- Marching squares edge table ---
	var edge_table = {
		1:  [[Vector2(0,0.5), Vector2(0.5,0)]],
		2:  [[Vector2(0.5,0), Vector2(1,0.5)]],
		3:  [[Vector2(0,0.5), Vector2(1,0.5)]],
		4:  [[Vector2(1,0.5), Vector2(0.5,1)]],
		5:  [[Vector2(0,0.5), Vector2(0.5,0)], [Vector2(1,0.5), Vector2(0.5,1)]],
		6:  [[Vector2(0.5,0), Vector2(0.5,1)]],
		7:  [[Vector2(0,0.5), Vector2(0.5,1)]],
		8:  [[Vector2(0.5,1), Vector2(0,0.5)]],
		9:  [[Vector2(0.5,0), Vector2(0.5,1)]],
		10: [[Vector2(0.5,0), Vector2(1,0.5)], [Vector2(0.5,1), Vector2(0,0.5)]],
		11: [[Vector2(1,0.5), Vector2(0.5,1)]],
		12: [[Vector2(0,0.5), Vector2(1,0.5)]],
		13: [[Vector2(0.5,0), Vector2(1,0.5)]],
		14: [[Vector2(0,0.5), Vector2(0.5,0)]],
	}
	
	'''var edge_table = {
		1:  [[Vector2(0,0.5), Vector2(0.5,0)]],
		2:  [[Vector2(0.5,0), Vector2(1,0.5)]],
		3:  [[Vector2(0,0.5), Vector2(1,0.5)]],
		4:  [[Vector2(1,0.5), Vector2(0.5,1)]],
		5:  [[Vector2(0,0.5), Vector2(0.5,0)], [Vector2(1,0.5), Vector2(0.5,1)]],
		6:  [[Vector2(0.5,0), Vector2(0.5,1)]],
		7:  [[Vector2(0,0.5), Vector2(0.5,1)]],
		8:  [[Vector2(0.5,1), Vector2(0,0.5)]],
		9:  [[Vector2(0.5,0), Vector2(0.5,1)]],
		10: [[Vector2(0.5,0), Vector2(1,0.5)], [Vector2(0.5,1), Vector2(0,0.5)]],
		11: [[Vector2(1,0.5), Vector2(0.5,1)]],
		12: [[Vector2(0,0.5), Vector2(1,0.5)]],
		13: [[Vector2(0.5,0), Vector2(1,0.5)]],
		14: [[Vector2(0,0.5), Vector2(0.5,0)]],
	}'''

	var segments: Array = []

	for gz in range(depth):
		for gx in range(width):
			var v0 = values[gz * (width + 1) + gx]
			var v1 = values[gz * (width + 1) + gx + 1]
			var v2 = values[(gz + 1) * (width + 1) + gx + 1]
			var v3 = values[(gz + 1) * (width + 1) + gx]
			var idx = int(v0) | int(v1) << 1 | int(v2) << 2 | int(v3) << 3

			# --- Interior edges via marching squares ---
			if idx != 0 and idx != 15 and edge_table.has(idx):
				for edge in edge_table[idx]:
					var p1 = Vector2(gx + edge[0].x, gz + edge[0].y)
					var p2 = Vector2(gx + edge[1].x, gz + edge[1].y)
					p1 = Vector2(x_min + p1.x / res, z_min + p1.y / res)
					p2 = Vector2(x_min + p2.x / res, z_min + p2.y / res)
					segments.append([p1, p2])

			# --- Boundary closure for hybrid polygons ---
			var active = v0 or v1 or v2 or v3
			if active:
				if gx == 0:
					segments.append([
						Vector2(x_min, z_min + (gz - 0.5) / res),
						Vector2(x_min, z_min + (gz + 0.5) / res)
					])
				if gx == width - 1:
					segments.append([
						Vector2(x_max, z_min + (gz - 0.5) / res),
						Vector2(x_max, z_min + (gz + 0.5) / res)
					])
				if gz == 0:
					segments.append([
						Vector2(x_min + (gx - 0.5) / res, z_min),
						Vector2(x_min + (gx + 0.5) / res, z_min)
					])
				if gz == depth - 1:
					segments.append([
						Vector2(x_min + (gx - 0.5) / res, z_max),
						Vector2(x_min + (gx + 0.5) / res, z_max)
					])

	# --- Chain into loops ---
	loops = _chain_segments_to_loops(segments)
	return loops





## Chain raw line segments into closed loops
##
## @param segments: segments to chain into one whole loop
## @return: the whole loop 2D array
func _chain_segments_to_loops(segments: Array) -> Array:
	"""
	Chain raw line segments into closed loops (robust version).
	Segments are [[Vector2, Vector2]].
	"""
	var loops: Array = []
	if segments.is_empty():
		return loops

	# Map from point -> list of connected points
	var adjacency := {}

	for seg in segments:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]

		if not adjacency.has(a):
			adjacency[a] = []
		if not adjacency.has(b):
			adjacency[b] = []

		adjacency[a].append(b)
		adjacency[b].append(a)

	var visited_points := {}

	for start in adjacency.keys():
		if visited_points.has(start):
			continue

		var loop: Array = []
		var current: Vector2 = start
		var prev: Vector2 = Vector2.INF

		while true:
			loop.append(current)
			visited_points[current] = true

			# pick next neighbor not equal to prev
			var next_point: Vector2 = Vector2.INF
			for n in adjacency[current]:
				if n != prev:
					next_point = n
					break

			if next_point == Vector2.INF:
				break

			prev = current
			current = next_point

			# if we’ve returned to start, loop is closed
			if current.distance_to(start) < 1e-4:
				break

		if loop.size() > 2:
			# close if nearly closed
			if loop.front().distance_to(loop.back()) < 1e-4:
				loop.pop_back()
			loops.append(PackedVector2Array(loop))

	return loops



## Creates the polygon mesh layer from loops
##
## @param loops: the complete loops
## @param y: the y level
## @return: node that is the polygon mesh object
func create_polygon_layer_from_loops(loops: Array, y: float) -> Node3D:
	var container := Node3D.new()
	if loops.is_empty():
		return container

	for loop in loops:
		if loop.size() < 3:
			continue

		# --- Clean loop: remove duplicates within epsilon ---
		var clean: Array = []
		for v in loop:
			if clean.is_empty() or v.distance_to(clean.back()) > 1e-4:
				clean.append(v)
		if clean.front().distance_to(clean.back()) < 1e-4:
			clean.pop_back()
		if clean.size() < 3:
			continue

		# --- Ensure CCW orientation ---
		if _polygon_area(clean) < 0:
			clean.reverse() # reverse order

		# convert to 3D verts
		var verts3: Array = []
		for p in clean:
			verts3.append(Vector3(p.x, y, p.y))

		# --- Triangulation ---
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var poly := PackedVector2Array(clean)
		var indices: PackedInt32Array = Geometry2D.triangulate_polygon(poly)

		if indices.is_empty():
			# fallback ear clipping
			indices = _ear_clip_triangulate(clean)

		if indices.is_empty():
			push_warning("Skipping bad polygon loop at y=%s" % str(y))
			continue

		for i in range(0, indices.size(), 3):
			var i0 = indices[i]
			var i1 = indices[i + 1]
			var i2 = indices[i + 2]
			st.set_normal(Vector3.UP)
			st.add_vertex(verts3[i0])
			st.add_vertex(verts3[i1])
			st.add_vertex(verts3[i2])

		var mesh := st.commit()
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		if fill_material:
			mesh_instance.material_override = fill_material
		container.add_child(mesh_instance)

	return container


## Finds the area of a polygon
##
## @param points: the polygon vertices
## @return: area of polygon
func _polygon_area(points: Array) -> float:
	# Signed area: >0 = CCW, <0 = CW
	var area := 0.0
	for i in range(points.size()):
		var j = (i + 1) % points.size()
		area += points[i].x * points[j].y - points[j].x * points[i].y
	return area * 0.5


## Ear clipping triangulation fallback
##
## @param points: the polygon points to clip
## @return: the trimmed polygon
func _ear_clip_triangulate(points: Array) -> PackedInt32Array:
	"""
	Ear clipping triangulation fallback.
	Input: Array[Vector2] (must be simple polygon, counterclockwise preferred)
	Output: PackedInt32Array of triangle vertex indices
	"""
	var n = points.size()
	var indices: Array = []
	for i in range(n):
		indices.append(i)

	var triangles: Array = []

	while indices.size() > 3:
		var ear_found = false
		for i in range(indices.size()):
			var i0 = indices[(i - 1 + indices.size()) % indices.size()]
			var i1 = indices[i]
			var i2 = indices[(i + 1) % indices.size()]

			var p0: Vector2 = points[i0]
			var p1: Vector2 = points[i1]
			var p2: Vector2 = points[i2]

			# Check if convex
			if (p1 - p0).cross(p2 - p0) <= 0:
				continue

			# Check no other point inside triangle
			var ear_valid = true
			for j in indices:
				if j == i0 or j == i1 or j == i2:
					continue
				if _point_in_triangle(points[j], p0, p1, p2):
					ear_valid = false
					break

			if ear_valid:
				triangles.append_array([i0, i1, i2])
				indices.remove_at(i)
				ear_found = true
				break

		if not ear_found:
			push_warning("Ear clipping failed: polygon may be self-intersecting or not simple")
			break

	# Last triangle
	if indices.size() == 3:
		triangles.append_array([indices[0], indices[1], indices[2]])

	return PackedInt32Array(triangles)


## Determines whether or not a point is inside a triange
##
## @param p: point
## @param a: triangle vertex a
## @param b: triangle vertex b
## @param c: triangle vertex c
## @return: is the point inside the triangle
func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 = c - a
	var v1 = b - a
	var v2 = p - a

	var dot00 = v0.dot(v0)
	var dot01 = v0.dot(v1)
	var dot02 = v0.dot(v2)
	var dot11 = v1.dot(v1)
	var dot12 = v1.dot(v2)

	var denom = dot00 * dot11 - dot01 * dot01
	if abs(denom) < 1e-6:
		return false

	var u = (dot11 * dot02 - dot01 * dot12) / denom
	var v = (dot00 * dot12 - dot01 * dot02) / denom
	return u >= 0 and v >= 0 and (u + v) < 1
