# GlobalSignals.gd
extends Node

# A single signal carrying both dot‐product values
signal dot_products_updated(palm_dot: float, head_dot: float)

signal block_button_pressed(person: String)

signal expression_entered(expr: String)

signal expression_entered_x(expr: String)

signal expression_entered_y(expr: String)

signal expression_entered_z(expr: String)

signal regen_mesh()

signal debug_message(expr: String)

signal scan_surroundings()

signal set_origin()

signal toggle_mesh_visibility()
