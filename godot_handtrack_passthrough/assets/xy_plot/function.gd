@tool
extends Node3D

var expression
var exp_string = ""
var degree = 0

var expression_x
var exp_string_x = ""
var expression_y
var exp_string_y = ""
var expression_z
var exp_string_z = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func initialize():
	parse()

func set_string(s: String, type: int):
	if type == 0:
		exp_string = s
	if type == 1:
		exp_string_x = s
	if type == 2:
		exp_string_y = s
	if type == 3:
		exp_string_z = s
	parse()
	
func add_string(s: String, type: int):
	if type == 0:
		exp_string += s
	if type == 1:
		exp_string_x += s
	if type == 2:
		exp_string_y += s
	if type == 3:
		exp_string_z += s
	parse()

func clear():
	exp_string = ""
	exp_string_x = ""
	exp_string_y = ""
	exp_string_z = ""
	parse()
	
func filter_string(original: String):
	original = original.replace(" ", "")
	original = original.replace("pi", "PI")
	original = original.replace("e", "MATH_CONSTANT_E")
	var i = 0;
	while i < original.length() - 1 and i < 100:
		var c1 = original[i]
		var c2 = original[i + 1]
		if c1.is_valid_int() and (c2 == "(" or c2 >= "A" and c2 <= "z"):
			original = original.insert(i + 1, "*")
		elif (c1 == ")" or c1 >= "A" and c1 <= "z") and c2.is_valid_int():
			original = original.insert(i + 1, "*")
		elif c1 == ")" and (c2 == "(" or c2 >= "A" and c2 <= "z"):
			original = original.insert(i + 1, "*")
		i += 1
	return original
	
func parse():
	expression = Expression.new()
	var parse_string = exp_string
	parse_string = filter_string(parse_string)
	if parse_string.substr(0, 4) == "z''=":
		degree = 2
		parse_string = parse_string.substr(4)
	elif parse_string.substr(0, 3) == "z\"=":
		degree = 2
		parse_string = parse_string.substr(3)
	elif parse_string.substr(0, 3) == "z'=":
		degree = 1
		parse_string = parse_string.substr(3)
	elif parse_string.substr(0, 2) == "z=":
		degree = 0
		parse_string = parse_string.substr(2)
	elif parse_string.contains("z"):
		degree = 3
		if parse_string.contains("="):
			var string_left = parse_string.substr(0, parse_string.find("="))
			var string_right = parse_string.substr(parse_string.find("=") + 1, parse_string.length())
			parse_string = string_left + "-(" + string_right + ")"
	else:
		degree = 0
	var error = expression.parse(parse_string, ["x", "y", "z"])
	if error == OK:
		print("Parsed expression: " + parse_string)
	else:
		print("Failed to parse expression: " + parse_string)
		expression.parse("", ["x", "y", "z"])

	expression_x = Expression.new()
	exp_string_x = filter_string(exp_string_x)
	error = expression_x.parse(exp_string_x, ["s", "t", "x"])
	if error == OK:
		print("Parsed expression x: " + exp_string_x)
	else:
		print("Failed to parse expression: " + exp_string_x)
		expression_x.parse("", ["s", "t", "x"])
	
	expression_y = Expression.new()
	exp_string_y = filter_string(exp_string_y)
	error = expression_y.parse(exp_string_y, ["s", "t", "y"])
	if error == OK:
		print("Parsed expression y: " + exp_string_y)
	else:
		print("Failed to parse expression: " + exp_string_y)
		expression_y.parse("", ["s", "t", "y"])
	
	expression_z = Expression.new()
	exp_string_z = filter_string(exp_string_z)
	error = expression_z.parse(exp_string_z, ["s", "t", "z"])
	if error == OK:
		print("Parsed expression z: " + exp_string_z)
	else:
		print("Failed to parse expression: " + exp_string_z)
		expression_z.parse("", ["s", "t", "z"])


	'''expression_z = Expression.new()
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
	print("Parsed expression implicit: " + string_left + "-(" + string_right + ")")'''
	
func calculate(x: float, y: float, z: float, type: int) -> float:
	'''var expression = Expression.new()
	#expression.parse("20 + 10*2 - 5/2.0")
	expression.parse("(x*x+z*z) / 100")
	var result = expression.execute()'''
	return expression.execute([x, y, z])
	
func calculate_para(s: float, t: float, x: float, type: int) -> float:
	'''var expression = Expression.new()
	#expression.parse("20 + 10*2 - 5/2.0")
	expression.parse("(x*x+z*z) / 100")
	var result = expression.execute()'''
	if type == 1:
		return expression_x.execute([s, t, x])
	if type == 2:
		return expression_y.execute([s, t, x])
	if type == 3:
		return expression_z.execute([s, t, x])
	return 0

# Bisection method implementation
func bisection(x: float, y: float, a: float, b: float, tolerance : float = 0.0001) -> float:
	var midpoint : float
	while sign(calculate(x, y, a, 3)) == sign(calculate(x, y, b, 3)):
		if abs(calculate(x, y, a, 3)) > abs(calculate(x, y, b, 3)):
			b = 2 * b - a
		else:
			a = 2 * a - b
	while (b - a) / 2 > tolerance:
		midpoint = (a + b) / 2
		if sign(calculate(x, y, midpoint, 3)) == sign(calculate(x, y, a, 3)):
			a = midpoint
		else:
			b = midpoint

	return (a + b) / 2

func getDegree() -> int:
	'''if exp_string.contains("z"):
		return 3
	elif exp_string.contains("z'"):
		return 1
	elif exp_string.contains("y''"):
		return 2
	if exp_string_z != "":
		return 0
	elif exp_string_dzdx != "" && exp_string_dzdy != "":
		return 1
	elif exp_string_d2zdx2 != "" && exp_string_d2zdy2 != "" && exp_string_d2zdxdy != "":
		return 2
	elif exp_string_implicit != "":
		return 3'''
	return degree
