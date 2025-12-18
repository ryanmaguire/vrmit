shader_type spatial;

uniform float fade_start_distance = 1.0;
uniform float fade_end_distance = 3.0;
uniform float fade_surface_distance = 1.5;
uniform float alpha_scale : hint_range(0.0, 1.0) = 1.0; // Declare a uniform for alpha scaling
uniform int surface_size = 0;
uniform vec3 surface_vertices[1000]; // Declares an array of 4 Ve
uniform mat4 transform;
//render_mode unshaded;
//render_mode cull_disabled;
render_mode unshaded, cull_disabled, depth_prepass_alpha;


void fragment() {
	ALBEDO = COLOR.rgb;

    // Get the distance from the camera to the current fragment
    //float distance = length(VERTEX - CAMERA_POSITION_WORLD);
    float distance = length(VERTEX);

    // Calculate the alpha value based on distance
    // smoothstep creates a smooth transition between 0.0 and 1.0
    float alpha = smoothstep(fade_end_distance, fade_start_distance, distance);

    // Set the ALPHA value for the fragment
    //ALPHA = COLOR.a * alpha * alpha_scale;


	if (surface_size > 0)  {
		float min_distance = fade_surface_distance;
		for (int i = 0; i < surface_vertices.length(); i++) {
			vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
			if (length(world_pos - (transform * vec4(surface_vertices[i], 1.0)).xyz) < min_distance) {
				min_distance = length(world_pos - (transform * vec4(surface_vertices[i], 1.0)).xyz);
			}
		}
		//ALPHA = COLOR.a * alpha * alpha_scale * (5.0 - min_distance) / 5.0;
		ALPHA = (fade_surface_distance - min_distance) / fade_surface_distance;
	} else {
		ALPHA = COLOR.a * alpha * alpha_scale;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
