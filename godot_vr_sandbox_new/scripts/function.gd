@tool
extends Node3D

var expression
var exp_string = ""

@export var x_press = false
@export var z_press = false
@export var plus_press = false
@export var times_press = false
@export var clear_press = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	if x_press:
		add_string("x")
		x_press = false
	if z_press:
		add_string("z")
		z_press = false
	if plus_press:
		add_string("+")
		plus_press = false
	if times_press:
		add_string("*")
		times_press = false
	if clear_press:
		clear()
		clear_press = false

func initialize():
	expression = Expression.new()
	parse()
	
func add_string(s: String):
	exp_string += s
	parse()
	
func delete_char():
	exp_string = exp_string.substr(0, exp_string.length() - 1)
	parse()

func clear():
	exp_string = ""
	parse()
	
func parse():
	expression.parse(exp_string, ["x", "z"])
	print("Parsed expression: " + exp_string)
	
func calculate(x: float, z: float) -> float:
	'''var expression = Expression.new()
	#expression.parse("20 + 10*2 - 5/2.0")
	expression.parse("(x*x+z*z) / 100")
	var result = expression.execute()'''
	if exp_string == "":
		return 0
	return expression.execute([x, z])
	#return (x*x+z*z) / 100;
