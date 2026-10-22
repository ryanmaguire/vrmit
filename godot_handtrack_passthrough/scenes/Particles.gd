extends Node

@onready var physics = get_parent() as Physics
const PhysicsTypes = preload("res://scripts/physics/PhysicsTypes.gd")

@export var particle_multimesh: PackedScene
@export var vector_field : Node3D
@export_range(30, 90, 1) var simulation_hz := 45

var trails: Array = []
var trail_mesh := ArrayMesh.new()
var trail_instance := MeshInstance3D.new()
var trail_material := StandardMaterial3D.new()

const TRAIL_LENGTH := 16

var mm_instance: MultiMeshInstance3D
var particle_count = 700
var previous_positions := PackedVector3Array()
var current_positions := PackedVector3Array()
var simulation_accumulator := 0.0

const SIMULATION_TIME_SCALE := 0.06
const MAX_SIMULATION_STEPS_PER_FRAME := 3

func _ready() -> void:
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.albedo_color = Color.WHITE
	trail_material.vertex_color_use_as_albedo = false
	trail_instance.material_override = trail_material
	trail_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func enable_particle_flow():
	await get_tree().create_timer(0.5).timeout

	if mm_instance == null:
		mm_instance = particle_multimesh.instantiate()
		mm_instance.multimesh.instance_count = particle_count
		vector_field.add_child(mm_instance)
	mm_instance.visible = true

	var initial_positions = physics.rk4.SetParticles(particle_count)
	previous_positions = PackedVector3Array(initial_positions)
	current_positions = PackedVector3Array(initial_positions)
	simulation_accumulator = 0.0

	for i in range(mm_instance.multimesh.instance_count):
		mm_instance.multimesh.set_instance_transform(i, Transform3D(Basis(), initial_positions[i]))

	trail_instance.mesh = trail_mesh
	if trail_instance.get_parent() == null:
		vector_field.add_child(trail_instance)
	trail_instance.visible = true
		
func disable_particle_flow():
	if mm_instance:
		mm_instance.visible = false
	trail_instance.visible = false
	
func clear_trails():
	trails.clear()
	for i in range(particle_count):
		trails.append(PackedVector3Array())
		
func particle_flow_upd(h):
	if mm_instance == null or current_positions.is_empty():
		return

	var fixed_step := SIMULATION_TIME_SCALE / float(simulation_hz)
	simulation_accumulator = minf(
		simulation_accumulator + h,
		fixed_step * float(MAX_SIMULATION_STEPS_PER_FRAME)
	)

	var steps_run := 0
	while (
		simulation_accumulator >= fixed_step
		and steps_run < MAX_SIMULATION_STEPS_PER_FRAME
	):
		previous_positions = current_positions
		var integration_result: Array = physics.rk4.StepIntegrate(fixed_step, 1)
		current_positions = integration_result[0]
		var regenerated_particles: PackedByteArray = integration_result[1]

		for i in range(regenerated_particles.size()):
			if regenerated_particles[i] != 0:
				trails[i].clear()
				previous_positions[i] = current_positions[i]

		append_trail_positions(current_positions)
		simulation_accumulator -= fixed_step
		steps_run += 1

	if steps_run > 0:
		rebuild_trail_mesh()

	var interpolation_weight := clampf(
		simulation_accumulator / fixed_step,
		0.0,
		1.0
	)
	for i in range(mm_instance.multimesh.instance_count):
		var display_position := previous_positions[i].lerp(
			current_positions[i],
			interpolation_weight
		)
		mm_instance.multimesh.set_instance_transform(
			i,
			Transform3D(Basis(), display_position)
		)
	
func update_trails(positions: PackedVector3Array):
	append_trail_positions(positions)
	rebuild_trail_mesh()

func append_trail_positions(positions: PackedVector3Array) -> void:
	for i in positions.size():
		var trail = trails[i]
		trail.append(positions[i])

		if trail.size() > TRAIL_LENGTH:
			trail.remove_at(0)

		trails[i] = trail

func rebuild_trail_mesh() -> void:
	trail_mesh.clear_surfaces()

	var segment_count := 0
	for trail in trails:
		segment_count += maxi(trail.size() - 1, 0)

	if segment_count == 0:
		return

	var vertices := PackedVector3Array()
	vertices.resize(segment_count * 2)

	var vertex_i := 0
	for trail in trails:
		for point_i in range(trail.size() - 1):
			vertices[vertex_i] = trail[point_i]
			vertices[vertex_i + 1] = trail[point_i + 1]
			vertex_i += 2

	var surface_arrays := []
	surface_arrays.resize(Mesh.ARRAY_MAX)
	surface_arrays[Mesh.ARRAY_VERTEX] = vertices
	trail_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, surface_arrays)
