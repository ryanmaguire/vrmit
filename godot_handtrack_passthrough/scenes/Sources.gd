extends Node

@onready var physics = get_parent()

const FieldObject = preload("res://scripts/physics/FieldObject.gd")
const PointCharge = preload("res://scripts/physics/PointCharge.gd")
const BarMagnet = preload("res://scripts/physics/BarMagnet.gd")

@export var pos_charge_scene : PackedScene
@export var neg_charge_scene : PackedScene
@export var bar_magnet_scene : PackedScene
@export var vector_field : Node3D

var field_objects : Array[FieldObject] = []

# HELPER FUNCTION
func spawn_object(pos, object : FieldObject):
	var too_close = false
	for obj in field_objects:
		if pos.distance_to(obj.pos) < 0.07:
			too_close = true
			break
	
	if not too_close:		
		field_objects.append(object)
		physics.rk4.AddObject(object)
		object.area.position = pos
		vector_field.add_child(object.area)
		if object.mesh.material_override:
			object.mesh.material_override = object.mesh.material_override.duplicate()
		else:
			object.mesh.material_override = object.mesh.get_active_material(0).duplicate()
			
func remove_object(i: int):
	physics.rk4.RemoveObject(i)
	vector_field.remove_child(field_objects[i].area)
	field_objects[i].area.queue_free()
	field_objects.remove_at(i)
			
func spawn_pt_charge(pos, q):
	var charge_area : Area3D
	if q < 0:
		charge_area = neg_charge_scene.instantiate()
	else:
		charge_area = pos_charge_scene.instantiate()

	var pt_charge = PointCharge.new(pos, q, charge_area)
	#e_field_changed = true
	spawn_object(pos, pt_charge)
 
func spawn_bar_magnet(pos, m):
	var bar_magnet_area = bar_magnet_scene.instantiate()
	var bar_magnet = BarMagnet.new(pos, m, bar_magnet_area)
	spawn_object(pos, bar_magnet)
