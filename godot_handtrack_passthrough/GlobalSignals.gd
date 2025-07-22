# GlobalSignals.gd
extends Node

# A single signal carrying both dot‐product values
signal dot_products_updated(palm_dot: float, head_dot: float)

signal block_button_pressed(person: String)

signal expression_entered(expr: String)

signal regen_mesh()
