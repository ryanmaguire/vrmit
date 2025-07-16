@tool
extends Node3D

var expression_z
var exp_string_z = ""
var expression_dzdx
var exp_string_dzdx = ""
var expression_dzdy
var exp_string_dzdy = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func initialize():
	expression_z = Expression.new()
	expression_dzdx = Expression.new()
	expression_dzdy = Expression.new()
	parse()

func set_string(s: String, type: int):
	if type == 0:
		exp_string_z = s
	elif type == 1:
		exp_string_dzdx = s
	elif type == -1:
		exp_string_dzdy = s
	parse()
	
func add_string(s: String, type: int):
	if type == 0:
		exp_string_z += s
	elif type == 1:
		exp_string_dzdx += s
	elif type == -1:
		exp_string_dzdy += s
	parse()
	
func delete_char(type: int):
	if type == 0:
		exp_string_z = exp_string_z.substr(0, exp_string_z.length() - 1)
	elif type == 1:
		exp_string_dzdx = exp_string_dzdx.substr(0, exp_string_dzdx.length() - 1)
	elif type == -1:
		exp_string_dzdy = exp_string_dzdy.substr(0, exp_string_dzdy.length() - 1)

	parse()

func clear():
	exp_string_z = ""
	exp_string_dzdx = ""
	exp_string_dzdy = ""
	parse()
	
func parse():
	expression_z.parse(exp_string_z, ["x", "y", "z"])
	expression_dzdx.parse(exp_string_dzdx, ["x", "y", "z"])
	expression_dzdy.parse(exp_string_dzdy, ["x", "y", "z"])
	print("Parsed expression z: " + exp_string_z)
	print("Parsed expression dz/dx: " + exp_string_dzdx)
	print("Parsed expression dz/dy: " + exp_string_dzdy)
	
func calculate(x: float, y: float, z: float, type: int) -> float:
	'''var expression = Expression.new()
	#expression.parse("20 + 10*2 - 5/2.0")
	expression.parse("(x*x+z*z) / 100")
	var result = expression.execute()'''
	if type == 0:
		if exp_string_z == "":
			return 0
		return expression_z.execute([x, y, z])
	elif type == 1:
		if exp_string_dzdx == "":
			return 0
		return expression_dzdx.execute([x, y, z])
	elif type == -1:
		if exp_string_dzdy == "":
			return 0
		return expression_dzdy.execute([x, y, z])
	return 0
	#return (x*x+z*z) / 100;

func getDegree() -> int:
	if exp_string_z != "":
		return 0
	elif exp_string_dzdx != "" && exp_string_dzdy != "":
		return 1
	return 0
