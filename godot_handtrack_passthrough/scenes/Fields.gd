extends Node

const PhysicsTypes = preload("res://scripts/physics/PhysicsTypes.gd")

# References
@onready var physics = get_parent() as Physics
@onready var e_field_line_instance := MeshInstance3D.new()
@onready var b_field_line_instance := MeshInstance3D.new()

@export var vector_field: Node3D
@export var arrow_multimesh: PackedScene

# Field line state
var e_field_line_mesh := ArrayMesh.new()
var b_field_line_mesh := ArrayMesh.new()
var e_field_material := StandardMaterial3D.new()
var b_field_material := StandardMaterial3D.new()
var field_line_count := 64
var all_e_lines: Array = []
var all_b_lines: Array = []

# Arrow state
var e_arrow_mm_instance: MultiMeshInstance3D
var b_arrow_mm_instance: MultiMeshInstance3D

var e_arrow_line_indices := PackedInt32Array()
var b_arrow_line_indices := PackedInt32Array()
var e_arrow_base_distances := PackedFloat32Array()
var b_arrow_base_distances := PackedFloat32Array()
var e_line_lengths := PackedFloat32Array()
var b_line_lengths := PackedFloat32Array()
var e_line_cumulative: Array = []
var b_line_cumulative: Array = []
var e_line_strengths: Array = []
var b_line_strengths: Array = []
var e_arrow_phase := 0.0
var b_arrow_phase := 0.0
var e_arrow_display_transforms: Array[Transform3D] = []
var b_arrow_display_transforms: Array[Transform3D] = []
var e_arrow_target_positions := PackedVector3Array()
var b_arrow_target_positions := PackedVector3Array()
var e_arrow_sample_positions := PackedFloat32Array()
var b_arrow_sample_positions := PackedFloat32Array()

var electric_object_is_moving := false
var magnetic_object_is_moving := false

var arrow_count := 0

# Arrow settings
var arrow_speed := 2.0
var arrow_spacing := 0.75
@export var show_arrows_while_moving := true
@export var max_arrows_per_field := 256
@export var electric_arrow_max_speed_multiplier := 3.75
@export var electric_arrow_speed_influence_radius := 1.25
@export_range(0.0, 60.0, 0.5) var arrow_smoothing_speed := 18.0
@export_range(0.0, 0.5, 0.005) var arrow_max_smoothing_lag := 0.03
@export_range(0.0, 2.0, 0.01) var arrow_discontinuity_distance := 0.12
@export_range(0.25, 1.0, 0.05) var weak_arrow_scale := 0.45
@export var electric_arrow_weak_color := Color("fef6d2ff")
@export var electric_arrow_strong_color := Color("d28703ff")
@export var magnetic_arrow_weak_color := Color("eae6feff")
@export var magnetic_arrow_strong_color := Color("824bf1ff")

func _ready() -> void:
	configure_field_material(e_field_material)
	configure_field_material(b_field_material)

	e_field_line_instance.material_override = e_field_material
	b_field_line_instance.material_override = b_field_material

func configure_field_material(material: StandardMaterial3D) -> void:
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color.WHITE

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func set_field_object_moving(field_type: int, is_moving: bool) -> void:
	if field_type == PhysicsTypes.FieldType.ELECTRIC_FIELD:
		electric_object_is_moving = is_moving

		if e_arrow_mm_instance:
			e_arrow_mm_instance.visible = (show_arrows_while_moving or not is_moving)

	elif field_type == PhysicsTypes.FieldType.MAGNETIC_FIELD:
		magnetic_object_is_moving = is_moving

		if b_arrow_mm_instance:
			b_arrow_mm_instance.visible = (show_arrows_while_moving or not is_moving)

func enable_e_field_lines():
	e_field_line_instance.mesh = e_field_line_mesh

	if e_field_line_instance.get_parent() == null:
		vector_field.add_child(e_field_line_instance)
	e_field_line_instance.visible = true

	if e_arrow_mm_instance == null:
		e_arrow_mm_instance = arrow_multimesh.instantiate()
		e_arrow_mm_instance.multimesh = (e_arrow_mm_instance.multimesh.duplicate())
		e_arrow_mm_instance.multimesh.instance_count = arrow_count
		vector_field.add_child(e_arrow_mm_instance)
	e_arrow_mm_instance.visible = (show_arrows_while_moving or not electric_object_is_moving)

func disable_e_field_lines() -> void:
	e_field_line_instance.visible = false
	if e_arrow_mm_instance:
		e_arrow_mm_instance.visible = false

func enable_b_field_lines():
	b_field_line_instance.mesh = b_field_line_mesh

	if b_field_line_instance.get_parent() == null:
		vector_field.add_child(b_field_line_instance)
	b_field_line_instance.visible = true

	if b_arrow_mm_instance == null:
		b_arrow_mm_instance = arrow_multimesh.instantiate()
		b_arrow_mm_instance.multimesh = (b_arrow_mm_instance.multimesh.duplicate())
		b_arrow_mm_instance.multimesh.instance_count = arrow_count
		vector_field.add_child(b_arrow_mm_instance)
	b_arrow_mm_instance.visible = (show_arrows_while_moving or not magnetic_object_is_moving)

func disable_b_field_lines() -> void:
	b_field_line_instance.visible = false
	if b_arrow_mm_instance:
		b_arrow_mm_instance.visible = false

func update_e_field_lines(h):
	var pt_charges: Array = []
	for obj in physics.sources.field_objects:
		if obj.object_type == PhysicsTypes.ObjectType.POINT_CHARGE:
			pt_charges.append(obj)

	if pt_charges.is_empty():
		e_field_line_mesh.clear_surfaces()
		all_e_lines.clear()
		e_arrow_line_indices.clear()
		e_arrow_base_distances.clear()
		e_line_lengths.clear()
		e_line_cumulative.clear()
		e_line_strengths.clear()
		e_arrow_display_transforms.clear()
		e_arrow_target_positions.clear()
		e_arrow_sample_positions.clear()
		if e_arrow_mm_instance:
			e_arrow_mm_instance.multimesh.instance_count = 0
		return

	all_e_lines = []

	var net_pos_seeds := PackedVector3Array()
	var net_neg_seeds := PackedVector3Array()

	var seeds_per_charge = int(field_line_count / pt_charges.size())
	for charge in pt_charges:
		var seeds = charge.generate_field_line_seeds(seeds_per_charge, 0.3, vector_field)

		if charge.q > 0:
			net_pos_seeds.append_array(seeds)
		else:
			net_neg_seeds.append_array(seeds)

	var pos_lines = build_field_lines(net_pos_seeds, h, PhysicsTypes.FieldType.ELECTRIC_FIELD)

	var neg_lines = build_field_lines(net_neg_seeds, -h, PhysicsTypes.FieldType.ELECTRIC_FIELD)

	for line in neg_lines:
		line.reverse()

	all_e_lines.append_array(pos_lines)
	all_e_lines.append_array(neg_lines)

	rebuild_field_mesh(all_e_lines, PhysicsTypes.FieldType.ELECTRIC_FIELD)

	rebuild_arrow_states(PhysicsTypes.FieldType.ELECTRIC_FIELD)

func update_b_field_lines(h):
	var bar_magnets: Array = []
	for obj in physics.sources.field_objects:
		if obj.object_type == PhysicsTypes.ObjectType.BAR_MAGNET:
			bar_magnets.append(obj)

	if bar_magnets.is_empty():
		b_field_line_mesh.clear_surfaces()
		all_b_lines.clear()
		b_arrow_line_indices.clear()
		b_arrow_base_distances.clear()
		b_line_lengths.clear()
		b_line_cumulative.clear()
		b_line_strengths.clear()
		b_arrow_display_transforms.clear()
		b_arrow_target_positions.clear()
		b_arrow_sample_positions.clear()
		if b_arrow_mm_instance:
			b_arrow_mm_instance.multimesh.instance_count = 0
		return

	all_b_lines = []

	var seeds := PackedVector3Array()
	var seeds_per_magnet = max(1, int(field_line_count / bar_magnets.size()))

	for magnet in bar_magnets:
		seeds.append_array(magnet.generate_field_line_seeds(seeds_per_magnet, 0.35, vector_field))

	all_b_lines = build_field_lines(seeds, h, PhysicsTypes.FieldType.MAGNETIC_FIELD)

	rebuild_field_mesh(all_b_lines, PhysicsTypes.FieldType.MAGNETIC_FIELD)

	rebuild_arrow_states(PhysicsTypes.FieldType.MAGNETIC_FIELD)

func rebuild_arrow_states(field_type: int) -> void:
	var lines := all_e_lines
	var arrow_instance := e_arrow_mm_instance
	var object_is_moving := electric_object_is_moving

	if field_type == PhysicsTypes.FieldType.MAGNETIC_FIELD:
		lines = all_b_lines
		arrow_instance = b_arrow_mm_instance
		object_is_moving = magnetic_object_is_moving

	if arrow_instance == null:
		return

	if object_is_moving and not show_arrows_while_moving:
		arrow_instance.visible = false
		return

	var line_indices := PackedInt32Array()
	var base_distances := PackedFloat32Array()
	var line_lengths := PackedFloat32Array()
	var cumulative_lines: Array = []
	line_lengths.resize(lines.size())
	cumulative_lines.resize(lines.size())
	var valid_line_indices := PackedInt32Array()
	var longest_line := 0.0

	for line_i in range(lines.size()):
		var line: PackedVector3Array = lines[line_i]
		var cumulative := PackedFloat32Array()

		if line.size() < 2:
			cumulative_lines[line_i] = cumulative
			continue

		cumulative.resize(line.size())
		cumulative[0] = 0.0
		var length := 0.0
		for point_i in range(1, line.size()):
			length += line[point_i - 1].distance_to(line[point_i])
			cumulative[point_i] = length

		line_lengths[line_i] = length
		cumulative_lines[line_i] = cumulative
		if length > 0.0:
			valid_line_indices.append(line_i)
			longest_line = maxf(longest_line, length)

	if not valid_line_indices.is_empty():
		var desired_layers: int = maxi(1, int(longest_line / arrow_spacing))
		var affordable_layers: int = maxi(1, floori(float(max_arrows_per_field) / valid_line_indices.size()))
		var layer_count: int = mini(desired_layers, affordable_layers)

		for layer_i in range(layer_count):
			var normalized_offset := float(layer_i) / layer_count
			for line_i in valid_line_indices:
				line_indices.append(line_i)
				base_distances.append(normalized_offset)

	if field_type == PhysicsTypes.FieldType.ELECTRIC_FIELD:
		e_arrow_line_indices = line_indices
		e_arrow_base_distances = base_distances
		e_line_lengths = line_lengths
		e_line_cumulative = cumulative_lines
	else:
		b_arrow_line_indices = line_indices
		b_arrow_base_distances = base_distances
		b_line_lengths = line_lengths
		b_line_cumulative = cumulative_lines

	arrow_instance.multimesh.instance_count = line_indices.size()

func build_field_lines(seeds: PackedVector3Array, h: float, field_type: int) -> Array:
	var max_steps := 150
	if field_type == PhysicsTypes.FieldType.MAGNETIC_FIELD:
		max_steps = 250

	return physics.rk4.BuildFieldLines(seeds, h, max_steps, field_type)

func rebuild_field_mesh(lines: Array, field_type: int) -> void:
	var mesh := e_field_line_mesh
	var material := e_field_material

	if field_type == PhysicsTypes.FieldType.MAGNETIC_FIELD:
		mesh = b_field_line_mesh
		material = b_field_material

	mesh.clear_surfaces()

	var has_segments := false
	for line in lines:
		if line.size() >= 2:
			has_segments = true
			break

	if not has_segments:
		return

	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for line in lines:
		if line.size() < 2:
			continue
		var vertex_offset := vertices.size()
		vertices.append_array(line)
		for i in range(line.size() - 1):
			indices.append(vertex_offset + i)
			indices.append(vertex_offset + i + 1)

	var colors: PackedColorArray = physics.rk4.GetFieldColors(vertices, field_type)
	var strengths: Array = []
	var color_i := 0
	for line in lines:
		var line_strengths := PackedFloat32Array()
		line_strengths.resize(line.size())
		if line.size() >= 2:
			for point_i in range(line.size()):
				line_strengths[point_i] = field_color_to_strength(colors[color_i], field_type)
				color_i += 1
		strengths.append(line_strengths)

	if field_type == PhysicsTypes.FieldType.ELECTRIC_FIELD:
		e_line_strengths = strengths
	else:
		b_line_strengths = strengths

	var surface_arrays := []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	surface_arrays[Mesh.ARRAY_VERTEX] = vertices
	surface_arrays[Mesh.ARRAY_COLOR] = colors
	surface_arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, surface_arrays)
	mesh.surface_set_material(0, material)

func field_color_to_strength(color: Color, field_type: int) -> float:
	if field_type == PhysicsTypes.FieldType.ELECTRIC_FIELD:
		return clampf(color.r, 0.0, 1.0)
	return clampf(1.0 - color.r, 0.0, 1.0)

func animate_field_arrows(delta: float) -> void:
	animate_arrows(delta, PhysicsTypes.FieldType.ELECTRIC_FIELD)

func animate_b_field_arrows(delta: float) -> void:
	animate_arrows(delta, PhysicsTypes.FieldType.MAGNETIC_FIELD)

func animate_arrows(delta: float, field_type: int) -> void:
	var lines := all_e_lines
	var line_indices := e_arrow_line_indices
	var base_distances := e_arrow_base_distances
	var line_lengths := e_line_lengths
	var cumulative_lines := e_line_cumulative
	var line_strengths := e_line_strengths
	var arrow_instance := e_arrow_mm_instance
	var object_is_moving := electric_object_is_moving
	var shared_phase := e_arrow_phase
	var display_transforms := e_arrow_display_transforms
	var previous_target_positions := e_arrow_target_positions
	var previous_sample_positions := e_arrow_sample_positions

	if field_type == PhysicsTypes.FieldType.MAGNETIC_FIELD:
		lines = all_b_lines
		line_indices = b_arrow_line_indices
		base_distances = b_arrow_base_distances
		line_lengths = b_line_lengths
		cumulative_lines = b_line_cumulative
		line_strengths = b_line_strengths
		arrow_instance = b_arrow_mm_instance
		object_is_moving = magnetic_object_is_moving
		shared_phase = b_arrow_phase
		display_transforms = b_arrow_display_transforms
		previous_target_positions = b_arrow_target_positions
		previous_sample_positions = b_arrow_sample_positions

	if arrow_instance == null:
		return

	if object_is_moving and not show_arrows_while_moving:
		arrow_instance.visible = false
		return

	arrow_instance.visible = true

	if line_indices.is_empty():
		return

	var previous_display_count := display_transforms.size()
	display_transforms.resize(line_indices.size())
	previous_target_positions.resize(line_indices.size())
	previous_sample_positions.resize(line_indices.size())
	var smoothing_weight := 1.0
	if arrow_smoothing_speed > 0.0:
		smoothing_weight = 1.0 - exp(-arrow_smoothing_speed * delta)

	var animation_reference_length := 0.0
	for line_i in line_indices:
		animation_reference_length = maxf(animation_reference_length, line_lengths[line_i])

	var charge_positions := PackedVector3Array()
	if field_type == PhysicsTypes.FieldType.ELECTRIC_FIELD:
		for field_object in physics.sources.field_objects:
			if (field_object.object_type == PhysicsTypes.ObjectType.POINT_CHARGE):
				charge_positions.append(field_object.pos)
	var proximity_sum := 0.0
	var proximity_count := 0
	var speed_influence_radius := maxf(electric_arrow_speed_influence_radius, 0.001)

	for i in range(line_indices.size()):
		var line_i: int = line_indices[i]
		var line: PackedVector3Array = lines[line_i]

		if line.size() < 2:
			continue

		var length: float = line_lengths[line_i]

		if length <= 0.0:
			continue

		var normalized_distance := fposmod(base_distances[i] + shared_phase, 1.0)
		var sample_value := normalized_distance * length
		var cumulative: PackedFloat32Array = cumulative_lines[line_i]

		var low := 1
		var high := cumulative.size() - 1
		while low < high:
			var middle := (low + high) >> 1
			if cumulative[middle] < sample_value:
				low = middle + 1
			else:
				high = middle

		var segment_i := low - 1
		var a: Vector3 = line[segment_i]
		var b: Vector3 = line[low]
		var segment := b - a
		var segment_length := (cumulative[low] - cumulative[segment_i])
		var t := 0.0
		if segment_length > 0.000001:
			t = (sample_value - cumulative[segment_i]) / segment_length

		var pos := a.lerp(b, t)
		var direction := segment.normalized()
		var strengths: PackedFloat32Array = line_strengths[line_i]
		var field_strength := lerpf(strengths[segment_i], strengths[low], t)
		if field_type == PhysicsTypes.FieldType.ELECTRIC_FIELD:
			var nearest_charge_distance := INF
			for charge_position in charge_positions:
				nearest_charge_distance = minf(nearest_charge_distance, pos.distance_to(charge_position))
			var proximity := 1.0 - clampf(nearest_charge_distance / speed_influence_radius, 0.0, 1.0)
			proximity_sum += proximity * proximity
			proximity_count += 1

		var up := Vector3.UP

		if abs(direction.dot(up)) > 0.999:
			up = Vector3.RIGHT

		var look_basis := Basis.looking_at(direction, up)
		var mesh_axis_correction := Basis(Vector3.RIGHT, -PI / 2.0)

		var arrow_scale := lerpf(weak_arrow_scale, 1.0, field_strength)
		var basis := (look_basis * mesh_axis_correction)
		basis = basis.scaled(Vector3.ONE * arrow_scale)
		var target_transform := Transform3D(basis, pos)
		var display_transform := target_transform

		if i < previous_display_count:
			var wrapped_to_line_start := (normalized_distance < previous_sample_positions[i])
			var target_discontinuity := (arrow_discontinuity_distance > 0.0 and previous_target_positions[i].distance_squared_to(pos) > arrow_discontinuity_distance * arrow_discontinuity_distance)
			if not wrapped_to_line_start and not target_discontinuity:
				var previous_transform := display_transforms[i]
				var smoothed_origin := previous_transform.origin.lerp(target_transform.origin, smoothing_weight)
				if arrow_max_smoothing_lag > 0.0:
					var lag_from_target := (smoothed_origin - target_transform.origin)
					if (lag_from_target.length_squared() > arrow_max_smoothing_lag * arrow_max_smoothing_lag):
						smoothed_origin = (target_transform.origin + lag_from_target.normalized() * arrow_max_smoothing_lag)
				var previous_rotation := previous_transform.basis.orthonormalized().get_rotation_quaternion()
				var target_rotation := target_transform.basis.orthonormalized().get_rotation_quaternion()
				var smoothed_rotation := previous_rotation.slerp(target_rotation, smoothing_weight)
				var smoothed_scale := previous_transform.basis.get_scale().lerp(target_transform.basis.get_scale(), smoothing_weight)
				display_transform = Transform3D(Basis(smoothed_rotation).scaled(smoothed_scale), smoothed_origin)

		display_transforms[i] = display_transform
		previous_target_positions[i] = pos
		previous_sample_positions[i] = normalized_distance
		arrow_instance.multimesh.set_instance_transform(i, display_transform)
		var weak_color := electric_arrow_weak_color
		var strong_color := electric_arrow_strong_color
		if field_type == PhysicsTypes.FieldType.MAGNETIC_FIELD:
			weak_color = magnetic_arrow_weak_color
			strong_color = magnetic_arrow_strong_color
		arrow_instance.multimesh.set_instance_color(i, weak_color.lerp(strong_color, field_strength))

	var speed_multiplier := 1.0
	if (field_type == PhysicsTypes.FieldType.ELECTRIC_FIELD and proximity_count > 0):
		speed_multiplier = lerpf(1.0, electric_arrow_max_speed_multiplier, proximity_sum / proximity_count)
	var normalized_speed := (arrow_speed / maxf(animation_reference_length, 0.001))
	shared_phase = fposmod(shared_phase + delta * normalized_speed * speed_multiplier, 1.0)

	if field_type == PhysicsTypes.FieldType.ELECTRIC_FIELD:
		e_arrow_phase = shared_phase
	else:
		b_arrow_phase = shared_phase
