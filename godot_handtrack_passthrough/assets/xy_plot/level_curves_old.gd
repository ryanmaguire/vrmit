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

func extract_level_loops(y_threshold: float) -> Array:
	var loops: Array = []
	if not surface.has_method("coordsToIndexReal") or surface.heights.is_empty():
		push_error("Surface does not provide heights or coordsToIndexReal")
		return loops

	var width = int((x_max - x_min) * res)
	var depth = int((z_max - z_min) * res)

	# --- Sample scalar field ---
	var values: Array = []
	var edge_points: Array = []
	var used: Array = []
	values.resize((width + 1) * (depth + 1))
	edge_points.resize((width + 1) * (depth + 1))
	used.resize((width + 1) * (depth + 1))
	for gz in range(depth + 1):
		for gx in range(width + 1):
			var x = x_min + gx / float(res)
			var z = z_min + gz / float(res)
			var idx = surface.coordsToIndexReal(int(x * res), int(z * res), true)
			if idx < 0 or idx >= surface.heights[0][0].size():
				continue
			var y_val = surface.heights[0][0][idx]
			values[gz * (width + 1) + gx] = y_val > y_threshold
			edge_points[gz * (width + 1) + gx] = gx != 0 && gx != width && gz != 0 && gz != depth && y_val > y_threshold
			used[gz * (width + 1) + gx] = false
			
	for gz in range(1, depth):
		for gx in range(1, width):
			if !values[gz * (width + 1) + gx]:
				if (!values[(gz - 1) * (width + 1) + gx - 1] && !values[(gz) * (width + 1) + gx - 1]
					&& !values[(gz + 1) * (width + 1) + gx - 1] && !values[(gz - 1) * (width + 1) + gx]
					&& !values[(gz + 1) * (width + 1) + gx] && !values[(gz - 1) * (width + 1) + gx + 1]
					&& !values[(gz) * (width + 1) + gx + 1] && !values[(gz + 1) * (width + 1) + gx + 1]):
						edge_points[gz * (width + 1) + gx] = true

	var segments: Array = []

	for gz in range(depth):
		for gx in range(width):
			if !edge_points[gz * (width + 1) + gx]:# && (values[gz * (width + 1) + gx - 1] || values[gz * (width + 1) + gx + 1] || values[(gz - 1) * (width + 1) + gx] || values[(gz + 1) * (width + 1) + gx]):
				var px = gx
				var pz = gz
				while !edge_points[gz * (width + 1) + gx]:
					print(str(px) + "," + str(pz))
					edge_points[pz * (width + 1) + px] = true
					if pz > 0 && !edge_points[(pz - 1) * (width + 1) + px]:
						pz -= 1
						segments.append([Vector2(x_min + px / res, z_min + (pz + 1) / res), Vector2(x_min + px / res, z_min + (pz + 1) / res)])
					elif pz < depth - 1 && !edge_points[(pz + 1) * (width + 1) + px]:
						pz += 1
						segments.append([Vector2(x_min + px / res, z_min + (pz - 1) / res), Vector2(x_min + px / res, z_min + pz / res)])
					elif px > 0 && !edge_points[(pz) * (width + 1) + px - 1]:
						px -= 1
						segments.append([Vector2(x_min + (px + 1) / res, z_min + pz / res), Vector2(x_min + px / res, z_min + pz / res)])
					elif px < width - 1 && !edge_points[(pz) * (width + 1) + px + 1]:
						px += 1
						segments.append([Vector2(x_min + (px - 1) / res, z_min + pz / res), Vector2(x_min + px / res, z_min + pz / res)])
					else:
						segments.append([Vector2(x_min + px / res, z_min + pz / res), Vector2(x_min + gx / res, z_min + gz / res)])
						break
					'''var xn = values[gz * (width + 1) + gx - 1]
					var xp = values[gz * (width + 1) + gx + 1]
					var zn = values[(gz - 1) * (width + 1) + gx]
					var zp = values[(gz + 1) * (width + 1) + gx]
					var p = Vector2(x_min + gx / res, z_min + gz / res)
					if (xn or xp) and !zn and !zp:
						segments.append([p + Vector2.DOWN, p + Vector2.UP])
					if (zn or zp) and !xn and !xp:
						segments.append([p + Vector2.LEFT, p + Vector2.RIGHT])
					if !xn and xp and !zn and zp:
						segments.append([p + Vector2.LEFT, p + Vector2.DOWN])
					if !xn and xp and zn and !zp:
						segments.append([p + Vector2.LEFT, p + Vector2.UP])
					if xn and !xp and !zn and zp:
						segments.append([p + Vector2.RIGHT, p + Vector2.DOWN])
					if xn and !xp and zn and !zp:
						segments.append([p + Vector2.RIGHT, p + Vector2.UP])
						#segments.append([p, p + Vector2.RIGHT])'''
			
			
			'''var v0 = values[gz * (width + 1) + gx]
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
					])'''

	# --- Chain into loops ---
	loops = _chain_segments_to_loops(segments)
	return loops






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


func _polygon_area(points: Array) -> float:
	# Signed area: >0 = CCW, <0 = CW
	var area := 0.0
	for i in range(points.size()):
		var j = (i + 1) % points.size()
		area += points[i].x * points[j].y - points[j].x * points[i].y
	return area * 0.5



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
