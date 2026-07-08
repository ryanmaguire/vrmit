class_name WireTool extends Node

## Wire tool

## Settings
const WIRE_START_DST := 0.06 # Distance between two pinch centers (m)
const WIRE_RADIUS := 0.012 # (m)
const WIRE_COLOR := Color(0.13, 0.13, 0.13, 1.0) # Any color object

## CircuitHands. If unset, resolved from [member group_hands].
@export var hands : CircuitHands
@export var group_hands : StringName = &"circuit_hands"

## Node the wire meshes are parented under. If unset, resolved from [member group_components].
@export var components : Node3D
@export var group_components : StringName = &"circuit_components"

## Global toggle. Set via [method set_active].
var active := false

var wires : Array = []

var _wire_drawing := false
var _last_a : Vector3
var _last_b : Vector3

var _wire_mat := StandardMaterial3D.new()
var _preview : MeshInstance3D


func _ready() -> void:
	if hands == null:
		hands = get_tree().get_first_node_in_group(group_hands)
	if components == null:
		components = get_tree().get_first_node_in_group(group_components)

	_wire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wire_mat.albedo_color = WIRE_COLOR

	_preview = MeshInstance3D.new()
	_preview.material_override = _wire_mat
	_preview.mesh = _new_wire_mesh()
	_preview.visible = false
	components.add_child(_preview)


func _process(_delta : float) -> void:
	if not active or hands == null:
		return

	var both_pinching := hands.both_pinching()

	if not _wire_drawing:
		if both_pinching and hands.pinch_separation() < WIRE_START_DST:
			_wire_drawing = true
	else:
		if hands.left.is_pinching() == false or hands.right.is_pinching() == false:
			finalize_wire(_last_a, _last_b)
			_wire_drawing = false
			_preview.visible = false
		else:
			_last_a = hands.right.pinch_center
			_last_b = hands.left.pinch_center
			update_preview(_last_a, _last_b)


## Global toggle for the wire tool. Will cancel any in-progress draw if disabled mid-draw.
func set_active(value : bool) -> void:
	print("[CircuitSIM/WIRE]: State recieved: ", value)
	active = value
	if not active:
		_wire_drawing = false
		if _preview:
			_preview.visible = false


## Remove all finalized wires and cancel any in-progress draw.
func clear() -> void:
	_wire_drawing = false
	if _preview:
		_preview.visible = false
	for w in wires:
		w.mesh.queue_free()
	wires.clear()


func update_preview(a : Vector3, b : Vector3) -> void:
	_orient_wire(_preview, a, b)


func finalize_wire(a : Vector3, b : Vector3) -> void:
	var inst := MeshInstance3D.new()
	inst.material_override = _wire_mat
	inst.mesh = _new_wire_mesh()
	components.add_child(inst)
	_orient_wire(inst, a, b)
	wires.append({"a": a, "b": b, "mesh": inst})


func _new_wire_mesh() -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = WIRE_RADIUS
	m.bottom_radius = WIRE_RADIUS
	m.radial_segments = 6
	m.rings = 1
	return m


func _orient_wire(inst : MeshInstance3D, a : Vector3, b : Vector3) -> void:
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
