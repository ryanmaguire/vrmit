@tool

extends "res://assets/xy_plot/surface.gd"

@export var expression_x: String
@export var expression_y: String
@export var expression_z: String

func _ready() -> void:
	super._ready();
	GlobalSignals.connect("expression_entered_para", _on_expression_entered_para)
	call_deferred("_on_expression_entered_para", "0", "0", "0")
	#_on_expression_entered_para("0", "0", "0")
	
## Signal function to send a newly entered parametric function
##
## @param exprX: expression for x
## @param exprY: expression for y
## @param exprZ: expression for z
func _on_expression_entered_para(exprX: String, exprY: String, exprZ: String):
	#print("New Expression: " + expr)
	#expression_z = expr
	if (exprX == "" or exprY == "" or exprZ == ""): 
		function.set_string(expression_x, 1)
		function.set_string(expression_y, 2)
		function.set_string(expression_z, 3)
	else:
		function.set_string(exprX, 1)
		function.set_string(exprY, 2)
		function.set_string(exprZ, 3)
	gen()
	
func _process(delta: float) -> void:
	super._process(delta)
	if parse and isParametric:
		_on_expression_entered_para("", "", "")
		parse = false
