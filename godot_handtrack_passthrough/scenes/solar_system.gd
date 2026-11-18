"""extends Node

@onready var physics = get_parent() as Physics
@export var vector_field: Node3D
@export var celestial_body: PackedScene

@export var distance_scale := 0.15 * 15
@export var simulation_speed := 0.3
const h := 0.005
const MAX_STEPS_PER_FRAME := 8
const TEXTURE_PATH := "res://assets/solar_system/textures/"

# Relative diameter, orbital radius (AU), mass (solar masses), texture.
var planet_info = {
	"Sun": [1.0, 0.0, 1.0, "2k_sun.jpg"],
	"Mercury": [1.0/285.4, 0.39, 1.0/6024000.0, "2k_mercury.jpg"],
	"Venus": [1.0/115.1, 0.72, 1.0/408000.0, "2k_venus_atmosphere.jpg"],
	"Earth": [1.0/109.2, 1.0, 1.0/333000.0, "2k_earth_daymap.jpg"],
	"Mars": [1.0/205.1, 1.52, 1.0/3098000.0, "2k_mars.jpg"],
	"Jupiter": [1.0/9.7, 5.2, 1.0/1047.0, "2k_jupiter.jpg"],
	"Saturn": [1.0/11.6, 9.56, 1.0/3500.0, "2k_saturn.jpg"],
	"Uranus": [1.0/27.2, 19.22, 1.0/22900.0, "2k_uranus.jpg"],
	"Neptune": [1.0/28.1, 30.11, 1.0/19400.0, "2k_neptune.jpg"]
}

var bodies: Array[Node3D] = []
var simulation_accumulator := 0.0
var initialized := false

func _ready() -> void:
	# Children become ready before Physics creates its @onready RK4 wrapper.
	call_deferred("generate_celestial_bodies")

func generate_celestial_bodies() -> void:
	if initialized:
		return
		
	var positions := PackedVector3Array()
	var velocities := PackedVector3Array()
	var masses := PackedFloat32Array()
	var center := Vector3.ZERO
	var momentum := Vector3.ZERO
	var total_mass := 0.0
	
	# 
	for body_name in planet_info:
		var info: Array = planet_info[body_name]
		var radius: float = info[1]
		var mass: float = info[2]
		var position := Vector3(radius, 0.0, 0.0)
		# Approximate circular heliocentric orbits; the integrator includes all bodies.
		var velocity := Vector3.ZERO
		if radius > 0.0:
			velocity.z = sqrt((1.0 + mass) / radius)
		positions.append(position)
		velocities.append(velocity)
		masses.append(mass)
		center += position * mass
		momentum += velocity * mass
		total_mass += mass

	for i in positions.size():
		positions[i] -= center / total_mass
		velocities[i] -= momentum / total_mass
	if not physics.rk4.SetSolarBodies(positions, velocities, masses):
		push_error("Could not initialize solar system bodies")
		return

	for body_name in planet_info:
		var info: Array = planet_info[body_name]
		var body := celestial_body.instantiate() as Node3D
		body.name = body_name
		var mesh := body.get_node("BodyMesh") as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_texture = load(TEXTURE_PATH + str(info[3])) as Texture2D
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = material
		# Exaggerated sizes keep planets visible in VR; orbital distances stay linear.
		var visual_size := 0.06 if body_name == "Sun" else maxf(0.025, sqrt(float(info[0])) * 0.5)
		body.scale = 15 * Vector3.ONE * visual_size
		vector_field.add_child(body)
		bodies.append(body)
	update_body_positions(positions)
	initialized = true

func _process(delta: float) -> void:
	if not initialized:
		return
	simulation_accumulator = minf(simulation_accumulator + delta * simulation_speed,
		h * MAX_STEPS_PER_FRAME)
	while simulation_accumulator >= h:
		var positions: PackedVector3Array = physics.rk4.StepSolarSystem(h)
		update_body_positions(positions)
		simulation_accumulator -= h

func update_body_positions(positions: PackedVector3Array) -> void:
	for i in bodies.size():
		bodies[i].position = positions[i] * distance_scale"""
