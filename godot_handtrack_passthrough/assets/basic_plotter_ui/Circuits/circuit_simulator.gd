extends HBoxContainer

@export var btn_global_circuits : Button
@export var btn_wire_tool : Button
@export var btn_clear_components : Button

const HandState = preload("res://assets/basic_plotter_ui/Physics/HandState.gd")

# Master switch for the whole circuit backend
var sim_enabled := false

var r_hand_state: HandState
var l_hand_state: HandState
var r_hand_pose_detector: HandPoseDetector
var l_hand_pose_detector: HandPoseDetector
var r_poke: XRToolsPoke
var l_poke: XRToolsPoke
var components: Node3D

var selected_tool = null

const WIRE_START_DST := 0.06
const WIRE_RADIUS := 0.012
const WIRE_COLOR := Color(0.13, 0.13, 0.13, 1.0)

var wire_drawing := false
var wires : Array = []

# wire endpoints
var last_a : Vector3
var last_b : Vector3

var wire_mat := StandardMaterial3D.new()
@onready var preview_instance := MeshInstance3D.new()

func _ready() -> void:
	components = get_tree().get_first_node_in_group("circuit_components")
	r_hand_pose_detector = get_tree().get_first_node_in_group("r_hand_pose_detector")
	l_hand_pose_detector = get_tree().get_first_node_in_group("l_hand_pose_detector")
	r_poke = get_tree().get_first_node_in_group("r_poke")
	l_poke = get_tree().get_first_node_in_group("l_poke")

	r_hand_state = HandState.new(r_hand_pose_detector)
	l_hand_state = HandState.new(l_hand_pose_detector)

	wire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wire_mat.albedo_color = WIRE_COLOR

	preview_instance.material_override = wire_mat
	preview_instance.mesh = _new_wire_mesh()
	preview_instance.visible = false
	components.add_child(preview_instance)

	if btn_global_circuits:
		btn_global_circuits.pressed.connect(_on_global_toggle)
	if btn_clear_components:
		btn_clear_components.pressed.connect(_on_clear_components)

func _process(_delta) -> void:
	if not visible or not sim_enabled:
		return

	r_hand_state.update(components)
	l_hand_state.update(components)

	var both_pinching = r_hand_state.is_pinching() and l_hand_state.is_pinching()

	if not wire_drawing:
		if both_pinching and r_hand_state.pinch_center.distance_to(l_hand_state.pinch_center) < WIRE_START_DST:
			wire_drawing = true
	else:
		if r_hand_state.released() or l_hand_state.released():
			finalize_wire(last_a, last_b)
			wire_drawing = false
			preview_instance.visible = false
		else:
			if both_pinching:
				last_a = r_hand_state.pinch_center
				last_b = l_hand_state.pinch_center
			update_preview(last_a, last_b)

func _on_global_toggle() -> void:
	sim_enabled = !sim_enabled
	if btn_global_circuits:
		btn_global_circuits.text = "Disable Circuits" if sim_enabled else "Enable Circuits"


func _on_clear_components() -> void:
	wire_drawing = false
	preview_instance.visible = false
	for w in wires:
		w.mesh.queue_free()
	wires.clear()

func _new_wire_mesh() -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = WIRE_RADIUS
	m.bottom_radius = WIRE_RADIUS
	m.radial_segments = 6
	m.rings = 1
	return m

func _orient_wire(inst: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var dir := b - a
	var length := dir.length()
	if length < 0.0001:
		inst.visible = false
		return
	inst.visible = true
	var mid := (a + b) * 0.5
	var n := dir / length
	var basis := Basis(Quaternion(Vector3.UP, n))
	inst.transform = Transform3D(basis, mid)
	inst.scale = Vector3(1.0, length * 0.5, 1.0)

func update_preview(a: Vector3, b: Vector3) -> void:
	_orient_wire(preview_instance, a, b)

func finalize_wire(a: Vector3, b: Vector3) -> void:
	var inst := MeshInstance3D.new()
	inst.material_override = wire_mat
	inst.mesh = _new_wire_mesh()
	components.add_child(inst)
	_orient_wire(inst, a, b)

	wires.append({"a": a, "b": b, "mesh": inst})
