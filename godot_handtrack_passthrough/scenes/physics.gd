class_name Physics extends Node

@onready var rk4: RK4Wrapper = RK4Wrapper.new()
@onready var sources = $Sources
@onready var fields = $Fields
@onready var particles = $Particles

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(rk4)
