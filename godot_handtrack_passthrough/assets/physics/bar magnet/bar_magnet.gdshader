shader_type spatial;

uniform vec3 blue : source_color = vec3(0.0, 0.0, 1.0);
uniform vec3 red : source_color = vec3(1.0, 0.0, 0.0);

void vertex() {
    // Called for every vertex the material is visible on.
    COLOR.r = VERTEX.y;
}

void fragment() {
	// Called for every pixel the material is visible on.
    float t = clamp(COLOR.r + 0.5, 0.0, 1.0);
    ALBEDO = mix(blue, red, t);
}