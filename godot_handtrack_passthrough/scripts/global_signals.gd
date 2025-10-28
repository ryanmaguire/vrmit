extends Node

@warning_ignore("unused_signal")
signal debug_message(message:String)

@warning_ignore("unused_signal")
signal block_button_pressed(person:String)

@warning_ignore("unused_signal")
signal set_origin()

@warning_ignore("unused_signal")
signal scan_surroundings()

@warning_ignore("unused_signal")
signal toggle_mesh_visibility()

@warning_ignore("unused_signal")
signal expression_entered(message:String)

@warning_ignore("unused_signal")
signal update_slider(value:float)

@warning_ignore("unused_signal")
signal set_rotating(is_on:bool)

@warning_ignore("unused_signal")
signal set_axis_visibility(is_visible:bool)

@warning_ignore("unused_signal")
signal update_plot_scale(scale:float)

@warning_ignore("unused_signal")
signal update_function_scale(scale:float)

###  CALCULUS OPTIONS MENU  ###
@warning_ignore("unused_signal")
signal set_level_curves(is_on:bool)

@warning_ignore("unused_signal")
signal set_tangent_plane(is_on:bool)

@warning_ignore("unused_signal")
signal set_grad_vector(is_on:bool)

@warning_ignore("unused_signal")
signal set_plane_grad_location(x:float, y:float)

###  VECTOR FIELD  ###
@warning_ignore("unused_signal")
signal expressions_entered(messageX:String, messageY:String, messageZ:String)

@warning_ignore("unused_signal")
signal set_field_render(type:int)
