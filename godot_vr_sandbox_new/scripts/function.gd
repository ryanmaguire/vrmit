@tool
extends Node3D

var expression_z
var exp_string_z = ""
var expression_dzdx
var exp_string_dzdx = ""
var expression_dzdy
var exp_string_dzdy = ""
var expression_d2zdx2
var exp_string_d2zdx2 = ""
var expression_d2zdy2
var exp_string_d2zdy2 = ""
var expression_d2zdxdy
var exp_string_d2zdxdy = ""
var expression_implicit
var exp_string_implicit = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func initialize():
	parse()

func set_string(s: String, type: int):
	if type == 0:
		exp_string_z = s
	elif type == 1:
		exp_string_dzdx = s
	elif type == -1:
		exp_string_dzdy = s
	elif type == 2:
		exp_string_d2zdx2 = s
	elif type == -2:
		exp_string_d2zdy2 = s
	elif type == 22:
		exp_string_d2zdxdy = s
	elif type == 3:
		exp_string_implicit = s
	parse()
	
func add_string(s: String, type: int):
	if type == 0:
		exp_string_z += s
	elif type == 1:
		exp_string_dzdx += s
	elif type == -1:
		exp_string_dzdy += s
	elif type == 2:
		exp_string_d2zdx2 += s
	elif type == -2:
		exp_string_d2zdy2 += s
	elif type == 22:
		exp_string_d2zdxdy += s
	elif type == 3:
		exp_string_implicit += s
	parse()
	
func delete_char(type: int):
	if type == 0:
		exp_string_z = exp_string_z.substr(0, exp_string_z.length() - 1)
	elif type == 1:
		exp_string_dzdx = exp_string_dzdx.substr(0, exp_string_dzdx.length() - 1)
	elif type == -1:
		exp_string_dzdy = exp_string_dzdy.substr(0, exp_string_dzdy.length() - 1)
	elif type == 2:
		exp_string_d2zdx2 = exp_string_d2zdx2.substr(0, exp_string_d2zdx2.length() - 1)
	elif type == -2:
		exp_string_d2zdy2 = exp_string_d2zdy2.substr(0, exp_string_d2zdy2.length() - 1)
	elif type == 22:
		exp_string_d2zdxdy = exp_string_d2zdxdy.substr(0, exp_string_d2zdxdy.length() - 1)
	elif type == 3:
		exp_string_implicit = exp_string_d2zdxdy.substr(0, exp_string_d2zdxdy.length() - 1)

	parse()

func clear():
	exp_string_z = ""
	exp_string_dzdx = ""
	exp_string_dzdy = ""
	exp_string_d2zdx2 = ""
	exp_string_d2zdy2 = ""
	exp_string_d2zdxdy = ""
	exp_string_implicit = ""
	parse()
	
func parse():
	expression_z = Expression.new()
	expression_dzdx = Expression.new()
	expression_dzdy = Expression.new()
	expression_d2zdx2 = Expression.new()
	expression_d2zdy2 = Expression.new()
	expression_d2zdxdy = Expression.new()
	expression_implicit = Expression.new()
	expression_z.parse(exp_string_z, ["x", "y", "z"])
	expression_dzdx.parse(exp_string_dzdx, ["x", "y", "z"])
	expression_dzdy.parse(exp_string_dzdy, ["x", "y", "z"])
	expression_d2zdx2.parse(exp_string_d2zdx2, ["x", "y", "z"])
	expression_d2zdy2.parse(exp_string_d2zdy2, ["x", "y", "z"])
	expression_d2zdxdy.parse(exp_string_d2zdxdy, ["x", "y", "z"])
	var string_left = exp_string_implicit.substr(0, exp_string_implicit.find("="))
	var string_right = exp_string_implicit.substr(exp_string_implicit.find("=") + 1, exp_string_implicit.length())
	expression_implicit.parse(string_left + "-(" + string_right + ")", ["x", "y", "z"])
	print("Parsed expression z: " + exp_string_z)
	print("Parsed expression dz/dx: " + exp_string_dzdx)
	print("Parsed expression dz/dy: " + exp_string_dzdy)
	print("Parsed expression d2z/dx2: " + exp_string_d2zdx2)
	print("Parsed expression d2z/dy2: " + exp_string_d2zdy2)
	print("Parsed expression implicit: " + string_left + "-(" + string_right + ")")
	
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
	elif type == 2:
		if exp_string_d2zdx2 == "":
			return 0
		return expression_d2zdx2.execute([x, y, z])
	elif type == -2:
		if exp_string_d2zdy2 == "":
			return 0
		return expression_d2zdy2.execute([x, y, z])
	elif type == 22:
		if exp_string_d2zdxdy == "":
			return 0
		return expression_d2zdxdy.execute([x, y, z])
	elif type == 3:
		if exp_string_implicit == "":
			return 0
		return expression_implicit.execute([x, y, z])
	return 0
	#return (x*x+z*z) / 100;

# Bisection method implementation
func bisection(x: float, y: float, a: float, b: float, tolerance : float = 0.0001) -> float:
	if sign(calculate(x, y, a, 3)) == sign(calculate(x, y, b, 3)):
		print("Error: Function values at a and b must have opposite signs.")
		return 0

	var midpoint : float
	while (b - a) / 2 > tolerance:
		midpoint = (a + b) / 2
		if sign(calculate(x, y, midpoint, 3)) == sign(calculate(x, y, a, 3)):
			a = midpoint
		else:
			b = midpoint

	return (a + b) / 2

func getDegree() -> int:
	if exp_string_z != "":
		return 0
	elif exp_string_dzdx != "" && exp_string_dzdy != "":
		return 1
	elif exp_string_d2zdx2 != "" && exp_string_d2zdy2 != "" && exp_string_d2zdxdy != "":
		return 2
	elif exp_string_implicit != "":
		return 3
	return 0
