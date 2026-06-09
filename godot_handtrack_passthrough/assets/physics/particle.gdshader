shader_type spatial;

render_mode unshaded, blend_add, cull_disabled;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = vec3(1.0);
	EMISSION = vec3(1.0);
	//ALPHA = 1.0 - UV.y;
	ALPHA = COLOR.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
