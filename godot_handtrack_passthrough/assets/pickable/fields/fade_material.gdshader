shader_type spatial;

uniform float fade_start_distance = 1.0;
uniform float fade_end_distance = 3.0;
uniform float alpha_scale : hint_range(0.0, 1.0) = 1.0; // Declare a uniform for alpha scaling
render_mode unshaded;
render_mode cull_disabled;

void fragment() {
	ALBEDO = COLOR.rgb;
	
    // Get the distance from the camera to the current fragment
    //float distance = length(VERTEX - CAMERA_POSITION_WORLD);
    float distance = length(VERTEX);

    // Calculate the alpha value based on distance
    // smoothstep creates a smooth transition between 0.0 and 1.0
    float alpha = smoothstep(fade_end_distance, fade_start_distance, distance);

    // Set the ALPHA value for the fragment
    ALPHA = COLOR.a * alpha * alpha_scale;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
