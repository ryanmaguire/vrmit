@tool

extends "res://assets/xy_plot/surface.gd"

func _ready() -> void:
	super._ready();
	GlobalSignals.connect("expression_entered", _on_expression_entered)
	call_deferred("_on_expression_entered", "0")
	#_on_expression_entered("0")
