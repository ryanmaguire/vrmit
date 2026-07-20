class_name WireTool extends Node

## Wire tool

## Settings
const WIRE_START_DST := 0.04 # Distance between two pinch centers (m)
const WIRE_RADIUS := 0.008 # (m) — preview only; real wires use the scene's mesh
const WIRE_COLOR := Color(0.8, 0.8, 0.8, 1.0) # preview only

## Template instanced once per finalized wire.
const WIRE_SCENE := preload("res://assets/circuit_simulation/components/scenes/wire.tscn")

## CircuitHands. If unset, resolved from [member group_hands].
@export var hands : CircuitHands
@export var group_hands : StringName = &"circuits/circuit_hands"

## Node the wire meshes are parented under. If unset, resolved from [member group_components].
@export var components : Node3D
@export var group_components : StringName = &"circuits/circuit_components"

## Registry used to find terminals to snap to. If unset, resolved from [member group_snap_manager].
@export var snap_manager : SnapPointManager
@export var group_snap_manager : StringName = &"circuits/snap_point_manager"

## Global toggle. Set via [method set_active].
var active := false

## Finalized [Wire] components created by this tool.
var wires : Array[Wire] = []

var _wire_drawing := false
var _last_a : Vector3
var _last_b : Vector3

# Terminals each end is currently hovering
var _last_snap_a : SnapPoint = null
var _last_snap_b : SnapPoint = null

var _wire_mat := StandardMaterial3D.new()
var _preview : MeshInstance3D


func _ready() -> void:
	if hands == null:
		hands = get_tree().get_first_node_in_group(group_hands)
	if components == null:
		components = get_tree().get_first_node_in_group(group_components)
	if snap_manager == null:
		snap_manager = get_tree().get_first_node_in_group(group_snap_manager)

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
			finalize_wire(_last_a, _last_b, _last_snap_a, _last_snap_b)
			_wire_drawing = false
			_preview.visible = false
			_last_snap_a = null
			_last_snap_b = null
		else:
			# Snap each end to the nearest free terminal if one is in range
			_last_snap_a = _resolve_snap(hands.right.pinch_center)
			_last_snap_b = _resolve_snap(hands.left.pinch_center)
			_last_a = _snapped_pos(hands.right.pinch_center, _last_snap_a)
			_last_b = _snapped_pos(hands.left.pinch_center, _last_snap_b)
			update_preview(_last_a, _last_b)


## Global toggle for the wire tool. Will cancel any in-progress draw if disabled mid-draw
func set_active(value : bool) -> void:
	print("[CircuitSim/wire_tool]: State recieved from menu: ", value)
	active = value
	if not active:
		_wire_drawing = false
		if _preview:
			_preview.visible = false


## Remove all finalized wires and cancel any in-progress draw
func clear() -> void:
	_wire_drawing = false
	if _preview:
		_preview.visible = false
	for w in wires:
		w.destroy()   # disconnects terminals + unregisters them from the manager
	wires.clear()


func update_preview(a : Vector3, b : Vector3) -> void:
	_orient_wire(_preview, a, b)


## Spawn the finalized wire component
func finalize_wire(a : Vector3, b : Vector3, snap_a : SnapPoint, snap_b : SnapPoint) -> void:
	var wire : Wire = WIRE_SCENE.instantiate()
	components.add_child(wire)
	wire.set_endpoints(a, b)

	# Avoid both ends grabbing the same terminal
	if snap_a != null and wire.snap_a:
		wire.snap_a.connect_to_snappoint(snap_a)
	if snap_b != null and snap_b != snap_a and wire.snap_b:
		wire.snap_b.connect_to_snappoint(snap_b)

	wires.append(wire)


func _resolve_snap(local_pos : Vector3) -> SnapPoint:
	if snap_manager == null:
		return null
	return snap_manager.nearest(components.to_global(local_pos))


func _snapped_pos(local_pos : Vector3, sp : SnapPoint) -> Vector3:
	if sp == null:
		return local_pos
	return components.to_local(sp.global_position)


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
