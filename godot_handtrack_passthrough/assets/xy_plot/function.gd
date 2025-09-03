@tool
extends Node3D

var expression
var exp_string = ""
var degree = 0
var hasSlider = false

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
	if original == "":
		original = "0"
	original = original.replace("pi", "PI")
	original = original.replace("e", "MATH_CONSTANT_E")
	original = original.replace("^", "**")
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
	hasSlider = false
	expression = Expression.new()
	var parse_string = exp_string
	parse_string = filter_string(parse_string)
	for j in parse_string.length():
		if parse_string.length() == 1:
			if parse_string == "a":
				hasSlider = true
		elif j == 0:
			if parse_string[j] == "a" and !(parse_string[j + 1] >= "A" and parse_string[j + 1] <= "z"):
				hasSlider = true
		elif j == parse_string.length() - 1:
			if parse_string[j] == "a" and !(parse_string[j - 1] >= "A" and parse_string[j - 1] <= "z"):
				hasSlider = true
		else:
			if parse_string[j] == "a" and !(parse_string[j + 1] >= "A" and parse_string[j + 1] <= "z") and !(parse_string[j - 1] >= "A" and parse_string[j - 1] <= "z"):
				hasSlider = true
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
	var error = expression.parse(parse_string, ["x", "y", "z", "a"])
	if error == OK:
		print("Parsed expression: " + parse_string)
	else:
		print("Failed to parse expression: " + parse_string)
		expression.parse("", ["x", "y", "z", "a"])

	expression_x = Expression.new()
	exp_string_x = filter_string(exp_string_x)
	for j in exp_string_x.length():
		if exp_string_x.length() == 1:
			if exp_string_x == "a":
				hasSlider = true
		elif j == 0:
			if exp_string_x[j] == "a" and !(exp_string_x[j + 1] >= "A" and exp_string_x[j + 1] <= "z"):
				hasSlider = true
		elif j == exp_string_x.length() - 1:
			if exp_string_x[j] == "a" and !(exp_string_x[j - 1] >= "A" and exp_string_x[j - 1] <= "z"):
				hasSlider = true
		else:
			if exp_string_x[j] == "a" and !(exp_string_x[j + 1] >= "A" and exp_string_x[j + 1] <= "z") and !(exp_string_x[j - 1] >= "A" and exp_string_x[j - 1] <= "z"):
				hasSlider = true
	error = expression_x.parse(exp_string_x, ["s", "t", "x", "a"])
	if error == OK:
		print("Parsed expression x: " + exp_string_x)
	else:
		print("Failed to parse expression: " + exp_string_x)
		expression_x.parse("", ["s", "t", "x", "a"])
	
	expression_y = Expression.new()
	exp_string_y = filter_string(exp_string_y)
	for j in exp_string_y.length():
		if exp_string_y.length() == 1:
			if exp_string_y == "a":
				hasSlider = true
		elif j == 0:
			if exp_string_y[j] == "a" and !(exp_string_y[j + 1] >= "A" and exp_string_y[j + 1] <= "z"):
				hasSlider = true
		elif j == exp_string_y.length() - 1:
			if exp_string_y[j] == "a" and !(exp_string_y[j - 1] >= "A" and exp_string_y[j - 1] <= "z"):
				hasSlider = true
		else:
			if exp_string_y[j] == "a" and !(exp_string_y[j + 1] >= "A" and exp_string_y[j + 1] <= "z") and !(exp_string_y[j - 1] >= "A" and exp_string_y[j - 1] <= "z"):
				hasSlider = true
	error = expression_y.parse(exp_string_y, ["s", "t", "y", "a"])
	if error == OK:
		print("Parsed expression y: " + exp_string_y)
	else:
		print("Failed to parse expression: " + exp_string_y)
		expression_y.parse("", ["s", "t", "y", "a"])
	
	expression_z = Expression.new()
	exp_string_z = filter_string(exp_string_z)
	for j in exp_string_z.length():
		if exp_string_z.length() == 1:
			if exp_string_z == "a":
				hasSlider = true
		elif j == 0:
			if exp_string_z[j] == "a" and !(exp_string_z[j + 1] >= "A" and exp_string_z[j + 1] <= "z"):
				hasSlider = true
		elif j == exp_string_z.length() - 1:
			if exp_string_z[j] == "a" and !(exp_string_z[j - 1] >= "A" and exp_string_z[j - 1] <= "z"):
				hasSlider = true
		else:
			if exp_string_z[j] == "a" and !(exp_string_z[j + 1] >= "A" and exp_string_z[j + 1] <= "z") and !(exp_string_z[j - 1] >= "A" and exp_string_z[j - 1] <= "z"):
				hasSlider = true
	error = expression_z.parse(exp_string_z, ["s", "t", "z", "a"])
	if error == OK:
		print("Parsed expression z: " + exp_string_z)
	else:
		print("Failed to parse expression: " + exp_string_z)
		expression_z.parse("", ["s", "t", "z", "a"])


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
	return calculate_a(x, y, z, 0, type)
	
func calculate_a(x: float, y: float, z: float, a: float, type: int) -> float:
	var X = x;
	var Y = y;
	var Z = z;
	if type == 1: # solve for x
		X = y
		Y = z
		Z = x
	if type == 2: # solve for y
		X = z
		Y = x
		Z = y
	
	var result = expression.execute([X, Y, Z, a])
	if is_nan(result) or is_inf(result):
		var left = expression.execute([X - 0.001, Y - 0.001, Z - 0.001, a - 0.001])
		var right = expression.execute([X + 0.001, Y + 0.001, Z + 0.001, a + 0.001])
		if abs(left - right) > 1:
			return NAN
		else:
			return (left + right) / 2
	else:
		return result
	
func calculate_para(s: float, t: float, x: float, type: int) -> float:
	return calculate_para_a(s, t, x, 0, type)
	
func calculate_para_a(s: float, t: float, x: float, a: float, type: int) -> float:
	if type == 1:
		var result = expression_x.execute([s, t, x, a])
		if is_nan(result) or is_inf(result):
			var left = expression_x.execute([s - 0.001, t - 0.001, x - 0.001, a - 0.001])
			var right = expression_x.execute([s + 0.001, t + 0.001, x + 0.001, a + 0.001])
			if abs(left - right) > 1:
				return NAN
			else:
				return (left + right) / 2
		else:
			return result
	if type == 2:
		var result = expression_y.execute([s, t, x, a])
		if is_nan(result) or is_inf(result):
			var left = expression_y.execute([s - 0.001, t - 0.001, x - 0.001, a - 0.001])
			var right = expression_y.execute([s + 0.001, t + 0.001, x + 0.001, a + 0.001])
			if abs(left - right) > 1:
				return NAN
			else:
				return (left + right) / 2
		else:
			return result
	if type == 3:
		var result = expression_z.execute([s, t, x, a])
		if is_nan(result) or is_inf(result):
			var left = expression_z.execute([s - 0.001, t - 0.001, x - 0.001, a - 0.001])
			var right = expression_z.execute([s + 0.001, t + 0.001, x + 0.001, a + 0.001])
			if abs(left - right) > 1:
				return NAN
			else:
				return (left + right) / 2
		else:
			return result
	return 0

# Bisection method implementation
func bisection(x: float, y: float, A: float, a: float, b: float, type: int = 0, tolerance : float = 0.01) -> float:
	if calculate_a(x, y, a, A, type) == 0:
		return a
	if calculate_a(x, y, b, A, type) == 0:
		return b
	var midpoint : float
	'''while sign(calculate(x, y, a, 3)) == sign(calculate(x, y, b, 3)):
		if abs(calculate(x, y, a, 3)) > abs(calculate(x, y, b, 3)):
			b = 2 * b - a
		else:
			a = 2 * a - b'''
	while (b - a) / 2 > tolerance:
		midpoint = (a + b) / 2
		if sign(calculate_a(x, y, midpoint, A, type)) == sign(calculate_a(x, y, a, A, type)):
			a = midpoint
		else:
			b = midpoint

	return (a + b) / 2
	
	
'''def bisection(f, a, b, tol=1e-7, max_iter=1000):
	if f(a) * f(b) >= 0:
		return None  # No sign change, no guarantee of root
	for _ in range(max_iter):
		c = (a + b) / 2
		fc = f(c)
		if abs(fc) < tol or (b - a) / 2 < tol:
			return c
		if f(a) * fc < 0:
			b = c
		else:
			a = c
	return None  # Did not converge'''

func find_all_roots(x: float, y: float, A: float, type: int, start=-100, end=100, steps=10, tol : float = 0.01):
	var roots = PackedFloat32Array()
	for i in range(steps):
		var a = start + i * (end - start) / steps
		var b = start + (i + 1) * (end - start) / steps
		if calculate_a(x, y, a, A, type) * calculate_a(x, y, b, A, type) <= 0:
			var root = bisection(x, y, A, a, b, tol)
			if true:#root is not None:
				# Avoid duplicate roots (within tolerance)
				if len(roots) == 0 or root != roots[len(roots) - 1]:
					roots.append(root)
				'''if all(abs(root - r) > tol for r in roots):
					roots.append(root)'''
	return roots

'''func solve_equation_all_roots(equation_str, start=-100, end=100):
	expr = parse_equation(equation_str)
	f = f_factory(expr)
	return find_all_roots(f, start, end)'''

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
	
